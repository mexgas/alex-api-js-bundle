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

	set @process = 'CW-4384 DROP SP ccsp_AGENTInsertCallOut'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AGENTInsertCallOut'')
		begin
			DROP PROCEDURE ccsp_AGENTInsertCallOut;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 create SP ccsp_AGENTInsertCallOut'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
	@cam_id smallint,
	@cal_Key varchar(40),
	@cal_Telefono varchar(30),
	@user_id int,
	@cal_extension varchar(7),
	@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
	@existCallOut as int = 0,
	@callmode as smallint = 0
	AS
	set 
	nocount on
	declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
	select @fecha=getdate()
	declare @dialPrefix integer
	select @dialPrefix = valor from ccSettings where setting_id = 202

	if @callmode = 1 begin
		INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
		select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension
		select @cal_id = scope_identity()

		insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
		select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
		from ccRIACampEspWG wg 
		where wg.tipo = 1 and wg.idcampesp =@cam_id

		select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
		select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
	  return(0)
	end

	if @existCallOut=0  begin
		declare @prefijoMarcacion varchar(100) 
		set @prefijoMarcacion = ''''
		declare @LasCallKey varchar(20)
		set @LasCallKey = @cal_Key
		declare @settingCallKey as int
		select @settingCallKey = valor from ccSettings where setting_id = 194
  
		if(@settingCallKey = 1) begin
			if (@cal_Key='''' or @cal_Key is null) begin   
				select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
				set @cal_Key= @LasCallKey
			end
		end

		if @dialPrefix = 1 and len(@cal_telefono)>20
			begin
				set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
				set @cal_telefono = RIGHT(@cal_telefono,10)		
			end
		else 
			begin
				set @prefijoMarcacion =''''			 
			end
	
		INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
		select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
		select @callout_id = scope_identity()

		INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
		select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
		select @cal_id = scope_identity()

	
	 end

	else begin --@existCallOut<>0
		Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
		Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
	
		set @callout_id = @existCallOut

		select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
	
		if exists(select * from ccoLogDials where cal_id=@cal_id) begin
			INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
			select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
			select @cal_id = scope_identity()
		end
	 
	 end
	
	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
	from dbo.ccRIACampEspWG wg 
	where wg.tipo = 1 and wg.idcampesp =@cam_id


	select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
	select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
	return(0)
	set nocount off
			'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_DLRSaveDialResult'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_DLRSaveDialResult'')
		begin
			DROP PROCEDURE ccsp_DLRSaveDialResult;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_DLRSaveDialResult'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
					@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
					@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
					@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)=
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

	set @process = 'CW-4384 DROP SP ccsp_DLRSaveDialResult_old3'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_DLRSaveDialResult_old3'')
		begin
			DROP PROCEDURE ccsp_DLRSaveDialResult_old3;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_DLRSaveDialResult_old3'
	set @sql = 'CREATE procedure [dbo].[ccsp_DLRSaveDialResult_old3]
						@callout_id int,
						@cam_id smallint,
						@tipoResDial_id tinyint,
						@Telefono varchar(30),
						@Puerto smallint,
						@tDialing tinyint=0,
						@tBusy smallint=0,
						@call_id int = 0,
						@answerbit bit = null,
						@tAnswerBit smallint = 0,
						@canceledNoAgents bit =0,
						@disconnectCause varchar(250) = '''',
						@cal_key varchar(40) = ''''
						AS
						set nocount on
						declare @tNow as datetime, @RecicleSIC tinyint
						declare @logDial_id int
						declare @tAnswerBitFinal as datetime

						SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
						select @tNow=getdate()

						select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)

						if @call_id > 0 and @tipoResDial_id = 1
						BEGIN
							Insert into dialogTemp values(@cam_id,@tDialing,@call_id)

							INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
							select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, 0, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
						END
						ELSE
						BEGIN
							Insert into dialogTemp values(@cam_id,@tDialing,@call_id)

							INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
							select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, 0, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key

						END

						select @logDial_id=scope_identity()

						if (@RecicleSIC=1)
						 begin
							UPDATE ccoWorkingTable SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
						 end

						select @logDial_id

						-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
						if @call_id > 0 and @tipoResDial_id = 1
						begin
							update ccoCallsOut set cal_manual = 2, cal_puerto = @Puerto	where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
							exec ccsp_CstoCalculaCosto @call_id

							if @cal_key ='''' begin
								select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
								update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
							end

						end

						-- inserta informacion para reportes de workgroup
						insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
						select IDWG, @logDial_id, IdCampEsp, getdate() 
						from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

						-- Guarda configuracion de TipoDialingMode
						update ccoLogDials set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
						set nocount off'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_DLRSaveDialResultnew'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_DLRSaveDialResultnew'')
		begin
			DROP PROCEDURE ccsp_DLRSaveDialResultnew;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_DLRSaveDialResultnew'
	set @sql = 'CREATE procedure [dbo].[ccsp_DLRSaveDialResultnew]
						@callout_id int,
						@cam_id smallint,
						@tipoResDial_id tinyint,
						@Telefono varchar(30),
						@Puerto smallint,
						@tDialing int=0,
						@tBusy smallint=0,
						@call_id int = 0,
						@answerbit bit = null,
						@tAnswerBit smallint = 0,
						@canceledNoAgents bit =0,
						@disconnectCause varchar(250) = '''',
						@cal_key varchar(40) = ''''
					
						AS
						set nocount on
						declare @tNow as datetime, @RecicleSIC tinyint
						declare @logDial_id int
						declare @tAnswerBitFinal as datetime

						SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
						select @tNow=getdate()

						select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)
						if @tDialing >=255 
							BEGIN
							select @tDialing =254
							end
						if @call_id > 0 and @tipoResDial_id = 1
						BEGIN
							INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
							select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
						END
						ELSE
						BEGIN
							INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
							select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
						END

						select @logDial_id=scope_identity()

						if (@RecicleSIC=1)
						 begin
							UPDATE ccoWorkingTable SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
						 end

						select @logDial_id

						-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
						if @call_id > 0 and @tipoResDial_id = 1
						begin
							update ccoCallsOut set cal_manual = 2, cal_puerto = @Puerto	where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
							exec ccsp_CstoCalculaCosto @call_id

							if @cal_key ='''' begin
								select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
								update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
							end

						end

						-- inserta informacion para reportes de workgroup
						insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
						select IDWG, @logDial_id, IdCampEsp, getdate() 
						from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

						-- Guarda configuracion de TipoDialingMode
						update ccoLogDials set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
						set nocount off'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_ExtAppsDisposeCall'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ExtAppsDisposeCall'')
		begin
			DROP PROCEDURE ccsp_ExtAppsDisposeCall;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_ExtAppsDisposeCall'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ExtAppsDisposeCall]
	@action as tinyint = 0,
	@type as tinyint = 0,
	@cal_id as smallint = 0,
	@disposition as smallint = 0,
	@subDisposition as smallint = 0,
	@date as varchar(50) = '''',
	@cam_id as smallint = 0
	AS
	declare @phone as varchar(15)
	declare @msg as int
	declare @needsCallback as int
	declare @pais varchar(2)
	declare @ld varchar(5)

	set @msg = 0 --No hizo nada

	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @ld = valor from ccSettings with(nolock) where setting_id = 17

	if @action = 1 begin  -- Califica y reprograma
		if @type = 1 begin	-- Inbound
		
			if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la calif padre
				select @needsCallback = canReprogram from ccTipoCalif where calif_id = @disposition			
			end else begin -- Si no buscamos en la tabla de las subcalifs
				select @needsCallback = canReprogram from ccTipoCalifSub where califSub_id = @subDisposition			
			end

			if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
				if @date <> '''' begin
					declare @acd_id as smallint			
					declare @phoneT as varchar(15)

					select @phone = cal_ani, @acd_id = inbound_id from cccallsin with(nolock) where cal_id = @cal_id
					select @cam_id = isnull(cam_id,0) from ccinbound with(nolock) where inbound_id = @acd_id
					select @phoneT = dbo.Completa(@phone, @pais, @ld)

					if @cam_Id <> 0 begin -- Si hay campaña espejo reprogramamos
						select @phone = case when left(@phoneT,1) = ''E'' then @phone else @phoneT end
						-- Genera callback
						exec ccsp_InInsertaCallBack '''', @cam_id, @phone, @date, '''','''','''','''','''',1,0
						-- Actualiza calificacion
						update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
						set @msg =  2 -- Reprogramacion Inbound
					end else begin				
						set @msg =  5 -- No hay campaña espejo para el acd	
					end
				end else begin				
					set @msg = 6 -- Necesita repgoramacion pero no hay fecha
				end
			end else begin -- Si no necesita repgoramacion se actualiza la calificacion
				update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
				set @msg = 1 -- Actualizo calificacion 
			end
		end
		else begin -- Outbound

			if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la tabla calif padre
				select @needsCallback = canReprogram from ccTipoCalifOut where calif_id = @disposition
			end else begin -- Si no buscamos en la tabla de las subcalifs
				select @needsCallback = canReprogram from ccTipoCalifSubOut where califSub_id = @subDisposition
			end

			if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
				if @date <> '''' begin 
					declare @callout_id int
					declare @cal_key as varchar(40)
				
					select @phone = cal_telefono, @cam_id = cam_id, @callout_id = callout_id, @cal_key = cal_key from ccocallsout with(nolock) where cal_id = @cal_id
					exec ccsp_OUTInsertaCallBack @cal_id, @phone, @cam_id, @date, @callout_id, 1, 0, @cal_key
					update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
					set @msg =  4 -- Reprogramacion Outbound
				end else begin
					set @msg = 6 -- Necesita repgoramacion pero no hay fecha
				end
			end else begin -- Si no necesita repgoramacion se actualiza la calificacion
				update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
				set @msg = 3 -- Actualizo calificacion 
			end

		end	
		select @msg
	end

	if @action = 2 begin
		if @type = 1 begin
			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 0 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type		
		end
		else begin
 			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback", 
 			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 1 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type
		end
	end

	if @action = 3 begin
		if @type = 1 begin
			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where tipo = 0 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type		
		end
		else begin
 			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
 			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where tipo = 1 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type
		end
	end'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_INInsertaCallBack'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_INInsertaCallBack'')
		begin
			DROP PROCEDURE ccsp_INInsertaCallBack;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_INInsertaCallBack'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_INInsertaCallBack]
	@cal_key varchar(40) ='''',
	@cam_id smallint,
	@cal_telefono varchar(19),
	@fechadial varchar(17),
	@dato1 varchar(255),
	@dato2 varchar(255),
	@dato3 varchar(255),
	@dato4 varchar(255),
	@dato5 varchar(255),
	@TelReprograma smallint = -1,
	@user_id int=0,
	@isAuto bit=0
	AS
	set nocount on
	declare @TelOriginal as varchar(15)
	declare @FechaOriginal as datetime

	if len(@cal_telefono)<=3
		return(0)

	if isnull(@cal_key,'''') = ''''
	 begin
		  -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
		  Genera_cal_key:
		  select @cal_key = right(newID(), 10)
		  if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
				goto Genera_cal_key
	 end

	declare @bIsDaylight as bit
	declare @idioma as int
	declare @country_id as varchar(3)

	select @country_id = valor from ccsettings where setting_id = 104

	select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

	declare @difference as int
	declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
	declare @iZonaHoraria2 int,@iZonaHoraria_verano2 int
	declare @iZonaHoraria3 int,@iZonaHoraria_verano3 int
	declare @iZonaHoraria4 int,@iZonaHoraria_verano4 int
	declare @iZonaHoraria5 int,@iZonaHoraria_verano5 int
	if @isAuto=0
		select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
	else
		set @difference = 0
	select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

	if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
	 begin
		select @callout_id=callout_id,@cal_statusTemp =cal_status,
		@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
		@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
		@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
		@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
		@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end, 
		@TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource 
		where cal_Key = @cal_key and cam_id = @cam_id

		update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

		if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
			UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
		else
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
			,iZonaHoraria,iZonaHoraria_verano
			,iZonaHoraria2,iZonaHoraria_verano2
			,iZonaHoraria3,iZonaHoraria_verano3
			,iZonaHoraria4,iZonaHoraria_verano4
			,iZonaHoraria5,iZonaHoraria_verano5)
			select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
			,@iZonaHoraria,@iZonaHoraria_verano
			,@iZonaHoraria2,@iZonaHoraria_verano2
			,@iZonaHoraria3,@iZonaHoraria_verano3
			,@iZonaHoraria4,@iZonaHoraria_verano4
			,@iZonaHoraria5,@iZonaHoraria_verano5

			if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
				begin
					insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
					values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
				end
			else
				begin
					update ccoCallBacks
					set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
					where callout_id = @callout_id
				end
	  end

	else
	 begin
		select @FechaOriginal = getdate()

		insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,cal_status)
		values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,''2'')

		select @TelOriginal = @cal_telefono

		select @callout_id = scope_identity()
		select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

		select @callout_id=callout_id,
		@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
		@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
		@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
		@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
		@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
		from ccoCallsOutSource 
		where callout_id=@callout_id


		 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
			UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
		 else
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
			,iZonaHoraria,iZonaHoraria_verano
			,iZonaHoraria2,iZonaHoraria_verano2
			,iZonaHoraria3,iZonaHoraria_verano3
			,iZonaHoraria4,iZonaHoraria_verano4
			,iZonaHoraria5,iZonaHoraria_verano5)
			select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
			,@iZonaHoraria,@iZonaHoraria_verano
			,@iZonaHoraria2,@iZonaHoraria_verano2
			,@iZonaHoraria3,@iZonaHoraria_verano3
			,@iZonaHoraria4,@iZonaHoraria_verano4
			,@iZonaHoraria5,@iZonaHoraria_verano5

			if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
				begin
					insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
					values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
				end
			else
				begin
					update ccoCallBacks
					set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
					where callout_id = @callout_id
				end
	end

	if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
		update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
	else
		insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

	return(0)
	set nocount off'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_IVRBeforeAskAge'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_IVRBeforeAskAge'')
		begin
			DROP PROCEDURE ccsp_IVRBeforeAskAge;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_IVRBeforeAskAge'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_IVRBeforeAskAge] @cal_id     INT, 
												  @Inbound_id SMALLINT, 
												  @cal_Key    VARCHAR(40), 
												  @callout_id INT
	AS
		 UPDATE ccCallsIn
		   SET 
			   Inbound_id = @Inbound_id, 
			   cal_key = @cal_Key, 
			   statusCall_id = 11, 
			   callout_id = @callout_id
		 WHERE cal_id = @cal_id'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_IVRInsertCallback'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_IVRInsertCallback'')
		begin
			DROP PROCEDURE ccsp_IVRInsertCallback;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_IVRInsertCallback'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_IVRInsertCallback] @ani    VARCHAR(40), 
													@cam_id SMALLINT
	AS
		 DECLARE @tel VARCHAR(20);
		 DECLARE @ld VARCHAR(4);
		 DECLARE @lon TINYINT;

		 --declare @result tinyint
		 SELECT @tel = RTRIM(LTRIM(@ani));
		 SELECT @tel = dbo.verifica(@tel);
		 IF LEFT(@tel, 1) <> ''E''
			 BEGIN
				 INSERT INTO ccoCallsOutSource
				 (cal_key, 
				  cal_telefono, 
				  cam_id
				 )
				 VALUES
				 (@ani, 
				  @tel, 
				  @cam_id
				 );
				 EXEC ccsp_RIAOUTInsertNewJOBS_WT_Camp 
					  @cam_id, 
					  0;
		 END;'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_OUTInsertaCallBack'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OUTInsertaCallBack'')
		begin
			DROP PROCEDURE ccsp_OUTInsertaCallBack;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_OUTInsertaCallBack'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_OUTInsertaCallBack]
	@cal_id int,
	@Telefono varchar(15),
	@Camp smallint,
	@FechaDial smalldatetime,
	@callout_id int=0,
	@TelReprograma smallint=-1,
	@user_id int=0,
	@cal_Key varchar(40)='''',
	@isAuto bit=0
	as
	set nocount on
	IF @TelReprograma<0
		  return(0)

	declare @Fecha smalldatetime, @sSQL nvarchar(max)
	declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
	declare @idZone int, @idZoneDaylight int, @list_id int
	declare @bIsDaylight bit, @difference int
	declare @TelOriginal varchar(15)
	declare @FechaOriginal datetime
	declare @pais varchar(2)
	declare @ld varchar(5)

	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @ld = valor from ccSettings with(nolock) where setting_id = 17

	select @callout_id = callout_id, @TelOriginal = cal_telefono, @FechaOriginal = cal_Inicio
	from ccocallsout
	where Cal_id=@cal_id

	IF @TelReprograma=0 --Otro telefono
	BEGIN
		  declare @tel2 varchar(20), @tel3 varchar(20), @tel4 varchar(20), @tel5 varchar(20)
		  declare @phoneCompleted varchar(20)
		  declare @emptyPhoneMsg varchar(50)

		  select @idZone = dbo.fnGetTimeZone(@Telefono,0)
		  select @idZoneDaylight = dbo.fnGetTimeZone(@Telefono,1)
		  select @phoneCompleted = dbo.Completa(@Telefono, @pais, @ld)
		  select @emptyPhoneMsg = case valor when 0 then ''El teléfono no puede ser nulo o vacío'' else ''Phone number can not be null or empty'' end from ccsettings where setting_id = 27

		  if charIndex(''E_NV'',@phoneCompleted) > 0
				set @phoneCompleted = @Telefono
				if @phoneCompleted = ''''
				begin
					  raiserror(@emptyPhoneMsg, 18, 1)
				end

		 select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
		 from ccoCallsoutSource where callout_id=@callout_id

		  select @TelReprograma=case when isnull(@tel4,'''')='''' then 4 when isnull(@tel3,'''')='''' then 3     when isnull(@tel2,'''')='''' then 2 else 5 end

		  select @sSQL=''update ccoCallsOutSource set cal_telefono''+cast(@TelReprograma as varchar(1))+''=''''''+@phoneCompleted+''''''''
		  +'',cal_status=2,iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
		  exec(@sSQL)
	END

	ELSE--@>0 telefono ya existente
	BEGIN
		  update ccoCallsOutSource set cal_status=2
		  where callout_id=@callout_id

		  select @sSQL= N''select @outA=cal_key, @outB=izonahoraria'' +replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outC=izonahoraria_verano''+replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outD= rtrim(left(ltrim(cal_telefono + ''''        ''''
				+ cal_telefono2 + ''''         ''''
				+ cal_telefono3 + ''''         ''''
				+ cal_telefono4 + ''''         ''''
				+ cal_telefono5 + ''''         ''''),13)) from ccoCallsOutSource where callout_id = '' +cast(@callout_id as varchar)
		  exec sp_executesql @sSQL, N''@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT'', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
	END

	-- PARA LA FECHA
	declare @country_id as int
	select @country_id = valor from ccsettings where setting_id = 104
	select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

	if @isAuto=0
		select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
	else
		set @difference = 0
	select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))
	update ccoCallsOut set cal_fcallback=@FechaDial where cal_id=@cal_id

	--PARA LAS ESTADISTICAS
	if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha) and mes=month(@Fecha) and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp)
		  update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp
	else
		  insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@Camp

	select @iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end, @iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end,
	 @iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, @iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end,
	@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, @iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end,
	@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, @iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end,
	@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end,
	@list_id=list_id
	from ccocallsoutsource where callout_id=@callout_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		begin
			UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
			cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
			iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
			iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
			iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
			iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
			iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
			WHERE callout_id=@callout_id
		end
	else
		begin
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
			[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
			iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5,list_id)
			select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
			@user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
			@iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5,@list_id
		end

	if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
		begin
			insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
			values (@callout_id,@user_id,@Camp,@cal_key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
		end
	else
		begin
			update ccoCallBacks
			set user_id = @user_id, cam_id = @Camp, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @Telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
			where callout_id = @callout_id
		end

	set nocount off'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_RIAAdmDelRegs'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAAdmDelRegs'')
		begin
			DROP PROCEDURE ccsp_RIAAdmDelRegs;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_RIAAdmDelRegs'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
		@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
		@cam_id int,
		@phone varchar(30) = '''',
		@calkey varchar(40) = '''',
		@exact bit = 1
		AS

		if @tipoDel = 1 --nuevos
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0
		 end

		if @tipoDel = 2 --callbacks
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1
		 end

		if @tipoDel = 3 -- 3 Registros sin meter a WT
		 begin
			update ccocallsoutsource --with(rowlock)
			set cal_Status = 5 
			where cam_id = @cam_id 
			and cal_status in(0, 7)
        
			Delete ccUploadTemporal where cam_id = @cam_id
		 end

		if @tipoDel = 4 --callbacks
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and user_id=0
		 end

		if @tipoDel = 5 --callbacks
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 3
		 end

		if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
		begin   
			delete ccoWorkingTable --with(rowlock) 
			where callout_id in (select callout_id 
									from ccocallsoutsource with(nolock)
									where cam_id = @cam_id 
									and (cal_telefono = @phone or 
											cal_telefono2 = @phone or 
											cal_telefono3 = @phone or 
											cal_telefono4 = @phone or 
											cal_telefono5 = @phone))

			update ccocallsoutsource --with(rowlock)
			set cal_Status = 5 
			where cam_id = @cam_id  and 
				(cal_telefono = @phone or 
				cal_telefono2 = @phone or 
				cal_telefono3 = @phone or 
				cal_telefono4 = @phone or 
				cal_telefono5 = @phone)
        
		end

		if @tipoDel = 7 -- Delete all the records from a specific campaign
		begin
			delete from ccoWorkingTable where cam_id = @cam_id

			update ccocallsoutsource set cal_Status = 5 where cam_id = @cam_id
		end

		if @tipoDel = 8 --delete records by specific callkey
		 begin
			if @exact = 1
				delete ccoWorkingTable with(rowlock) where cal_keyw = @calkey and cal_status <> 2
			else
				delete ccoWorkingTable with(rowlock) where cal_keyw like ''%'' + @calkey + ''%'' and cal_status <> 2
		 end'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_RIAOUTInsertNewJOBS_WT_Camp'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAOUTInsertNewJOBS_WT_Camp'')
		begin
			DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_WT_Camp;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_RIAOUTInsertNewJOBS_WT_Camp'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1
	AS
	SET NOCOUNT ON

	CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

	DECLARE @prioridad VARCHAR(8)
	DECLARE @batchsizeIni AS INT
	DECLARE @batchsizeFin AS INT
	DECLARE @rango AS DECIMAL
	DECLARE @rowstoInsert AS INT
	declare @top int

	SET @rowstoInsert = 0
	SET @batchsizeIni = 0
	SET @batchsizeFin = 0
	SET @rango = 0.00
	set @top=3000

	SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
	FROM ccCampsPrioridadTel WITH (NOLOCK)
	WHERE cam_id = @camp_id

	DELETE ccUploadTemporal
	WHERE cam_id = @camp_id

	CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

	CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

	CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

	INSERT INTO #calloutIdSource
	SELECT top(@top) cs.callout_id
	FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
	inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
	on cs.cal_key = wt.cal_keyw AND cs.cam_id = wt.cam_id 
	WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

	UNION

	SELECT top(@top) Cout.callout_id
	FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
	inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
	WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)

	INSERT INTO #calloutIdSource2
	SELECT top(@top) callout_id
	FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
	WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

	IF exists(SELECT * FROM #calloutIdSource) 
	BEGIN
		UPDATE ccoCallBacks
		SET [status] = 6, schedulerStatus = 1
		WHERE callout_id IN (
				SELECT callout_id
				FROM #calloutIdSource cis
				)

		UPDATE ccoCallsOutSource
		SET cal_Status = 4
		WHERE callout_id IN (
				SELECT callout_id
				FROM #calloutIdSource cis
				)
	END

	INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
	iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
	 iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
	SELECT top(@top) callout_id, cam_id, rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
	+ cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) AS cal_telefono,
	 CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
	 CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
	  CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
	  CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
	   CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
	   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
	   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
		CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
		CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
		CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
		CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
				NULL END iZonaHoraria_verano5, list_id
	FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
	WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

	SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

	IF exists(SELECT * FROM #tempCallsOutSource)
	BEGIN
		SELECT @rango = isnull(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
		FROM #tempCallsOutSource WITH (NOLOCK)

		SET @batchsizeFin = @batchsizeFin + @rango

		WHILE 1 = 1
		BEGIN
			-- Nuevos Jobs
			INSERT INTO ccoWorkingTable
			WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
			SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
			FROM #tempCallsOutSource
			WHERE id > @batchsizeIni AND id <= @batchsizeFin

			IF @batchsizeFin > @rowstoInsert
				BREAK
			ELSE
			BEGIN
				SET @batchsizeIni = @batchsizeIni + @rango
				SET @batchsizeFin = @batchsizeFin + @rango
			END
		END

		UPDATE ccoCallsOutSource
		SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
		FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
		WHERE co.callout_id = cis3.callout_id
	END

	DROP TABLE #calloutIdSource

	DROP TABLE #calloutIdSource2

	DROP TABLE #tempCallsOutSource

	UPDATE ccCampsNvosCB
	SET dateUpdate = NULL
	WHERE id = @camp_id

	SET NOCOUNT OFF'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_RIAUpdateCallKey'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCallKey'')
		begin
			DROP PROCEDURE ccsp_RIAUpdateCallKey;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_RIAUpdateCallKey'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCallKey] @type    TINYINT, 
												   @callid  INT, 
												   @callkey VARCHAR(40)
	AS
		 IF @type = 1 --Inbound 
			 BEGIN
				 UPDATE ccCallsIn
				   SET 
					   cal_key = @callkey
				 WHERE cal_id = @callid;
		 END;
		 IF @type = 2 --Outbound 
			 BEGIN
				 UPDATE ccoCallsOut
				   SET 
					   cal_key = @callkey
				 WHERE cal_id = @callid;
		 END;'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_SaveStatusAgent'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_SaveStatusAgent'')
		begin
			DROP PROCEDURE ccsp_SaveStatusAgent;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_SaveStatusAgent'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_SaveStatusAgent]
	@User_id smallint,
	@TipoStatusAge_id tinyint,
	@TipoNotReady tinyint,
	@tStatus float,
	@TipoCall  tinyint,
	@Camp smallint,
	--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
	@callout_id int=0,
	@call_id int=0,
	@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
	@tDialog int =0 ,
	@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
	@Fecha4 datetime=null,
	@tMusicHold int =0,
	@isTransferEngine bit = 0
	AS

	if @Fecha4 is null set @Fecha4 = getdate()

	if @TipoCall > 0 set @TipoCall = @TipoCall - 1

	if (@User_id > 0 ) begin

	declare @cam_id int,@surveycamId int
	declare @cal_telefono varchar(30)
	declare @cal_key varchar(40)
	declare @inbound_id int
	declare @callBackSurveyClients bit
	declare @cal_whoHung tinyint
	declare @cal_tDialog int
	declare @cal_tNotas int
	declare @cal_tNotaOri int
	declare @tMinAVRS smallint
	declare @calInicio datetime
	declare @sumCall int
	declare @cal_manual int 

	set @cal_tNotas =0
	set @cal_tNotaOri=0
	--4 Dialog,6 Notas, 27 Notas Fallida
	if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
	if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
	if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


	set @cal_manual =0

	if @TipoCall = 0 begin --IN

	select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
		  from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

	if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
	  if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
		set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
		if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
		if @TipoStatusAge_id=6  begin
		  if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
		  else  set @tDialog=@tDialog-1
		end
	  end
	  update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
	end
	end
	else begin --OUT
	select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
	@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
	set @Camp=@cam_id

	if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
	  if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
		set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
		if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
		if @TipoStatusAge_id=6  begin
		  if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
		  else  set @tDialog=@tDialog-1
		end
	  end

	  update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
	end
	else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
	  update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  where cal_id = @call_id
	else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
	  update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
	end

	select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

	if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
	  insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
	end

	if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
	--Valida que el agente no pudo guardar el status antes de desloguear
	if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
	  INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
	end


	end


	if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
	declare @tStatus3 int, @Fecha3 datetime
	select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
	insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
	select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
	from cccampsagente where user_id = @User_id


	---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
	if @call_id>0 begin
	if @TipoCall = 0 begin --IN

		select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

		if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
		  if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
			begin
			  if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
			  begin
				insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
				values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
			  end
			end
		end
	end --@TipoCall = 0
	else begin  --OUT



	  select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
	  select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
		from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

	  if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
		if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
		begin
		  insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
		  values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
		end
	  end
	end
	end--@isTransferSurvey = 0 and @callout_id>0


	end

	if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
	declare @minimoDialogo tinyint 
	select  @minimoDialogo = valor from ccSettings where setting_id = 13
	if @cal_tDialog < @minimoDialogo
	  begin
	  --el status 18 es para llamada cortada con transferencia en Reminder
	  exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
	end

	end 

	if @TipoStatusAge_id =6  and @isLogout=0
	begin
	--Valida que el ccserver no haya guardado antes el status antes al desloguear
	if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
	  INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
	end
	else
	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )

	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
	INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

	---Para Agente RIA: OAYC
	INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
	VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
	begin
	if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
		  where IdCampEsp = 0 and user_id = @User_id)
	  begin
		update ccLogAgentesDia with(rowlock)
		set IdCampEsp = @Camp, Tipo = @TipoCall
		where IdCampEsp = 0
		and user_id = @User_id
	  end

	if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
		  where IdCampEsp = 0 and user_id = @User_id)
	  begin
		update ccLogAgentesNotReady with(rowlock)
		set IdCampEsp = @Camp, Tipo = @TipoCall
		where IdCampEsp = 0
		and user_id = @User_id
	  end
	end
	end
	'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_TideWater_ABCTemplate'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_TideWater_ABCTemplate'')
		begin
			DROP PROCEDURE ccsp_TideWater_ABCTemplate;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_TideWater_ABCTemplate'
	set @sql = 'CREATE procedure [dbo].[ccsp_TideWater_ABCTemplate]
	@Type tinyint, -- 1:add | 2:delete | 3:update
	@Temp_id smallint = NULL,
	@Temp_Desc varchar(80) = NULL,
	@ConnString varchar(100) = NULL,
	@PathFile varchar(100) = NULL,
	@User_id smallint = NULL,
	@cam_id smallint = NULL,
	@TableName varchar(50) = NULL,
	@Tipo_Filtro tinyint = NULL,	-- Verificar en: select * from ccTipoFiltro
	@AceptaCel bit = 0,
	@tipo_Con tinyint = 0,
	@Where_Array varchar(8000) = NULL,
	@idtipolista_array varchar(4000) = NULL,
	@cal_Key_col varchar(40) = NULL,
	@cal_telefonos varchar(255) = NULL,
	@ColumnAssigned varchar(2000) = NULL,
	@cal_callback_col varchar(35) = NULL,
	@hasHeader bit = NULL,
	@nameList varchar(255) = NULL

	as
	set nocount on
	if @Type=1 -- add
	 begin
		if isnull(@Temp_Desc,'''')='''' or isnull(@TableName,'''')='''' or isnull(@cal_Key_col,'''')=''''
		 begin
			raiserror(''ERROR. invalid input data'', 18, 2)
			return(0)
		 end

		if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
		 begin
			raiserror(''ERROR. invalid user id'', 18, 1)
			return(0)
		 end

		if not exists(select cam_id from ccCamps where cam_activo=1 and cam_id=@cam_id and 
		 IDArea in (select IDArea from ccUsers where User_id=@User_id))
		 begin
			raiserror(''ERROR. invalid campaign'', 18, 1)
			return(0)
		 end

		if (select COUNT(id) from dbo.fn_RIASplitDelimited(@cal_telefonos, '',''))<>5
		 begin
			raiserror(''ERROR. invalid telephone array'', 18, 1)
			return(0)
		 end

		if (select COUNT(id) from dbo.fn_RIASplitDelimited(@ColumnAssigned, '',''))<>
		 (select COUNT(id) from ccodatos) and isnull(@ColumnAssigned,''&'')<>''&''
		 begin
			raiserror(''ERROR. invalid aditional data array'', 18, 1) 
			return(0)
		 end

		if not exists(select Tipo_Filtro from ccTipoFiltro where Status_Filtro=1 and Tipo_Filtro=@Tipo_Filtro)
		 begin
			raiserror(''ERROR. invalid filter'', 18, 1)
			return(0)
		 end
		
		insert ccTideWater_Templates (Temp_Desc, ConnString, PathFile, User_id, cam_id, TableName, Tipo_Filtro, 
		 AceptaCel, tipo_Con, Where_Array, idtipolista_array, cal_Key_col, cal_telefono_col, cal_telefono2_col, 
		 cal_telefono3_col, cal_telefono4_col, cal_telefono5_col, cal_callback_col, hasHeader, nameList)
		select @Temp_Desc, @ConnString, @PathFile, @User_id, @cam_id, @TableName, @Tipo_Filtro, 
		 @AceptaCel, @tipo_Con, @Where_Array, @idtipolista_array, @cal_Key_col, 
		(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1),
		(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2),
		(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3),
		(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4),
		(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5),	 
		 @cal_callback_col,@hasHeader,@nameList

		select @Temp_id=SCOPE_IDENTITY()
		if isnull(@Temp_id,0)=0
		 begin
			raiserror(''ERROR. insert can not be reached'', 18, 2)
			return(0)
		 end

		if isnull(@ColumnAssigned,''&'')<>''&''
		 begin
			insert ccTideWater_Templates_Cols (Temp_id, id, ColumnAssigned)
			 select @Temp_id, D.id, S.value from ccodatos D join dbo.fn_RIASplitDelimited(@ColumnAssigned, '','') S 
			 on D.id=S.id order by D.id

			if @@ROWCOUNT<1
			 begin
				delete ccTideWater_Templates where Temp_id=@Temp_id
				raiserror(''ERROR. insert 2 can not be reached'', 18, 1)
				return(0)
			 end
		 end

		select @Temp_id
		return(0)
	 end

	if @Type=2 -- delete
	 begin
		if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
		 begin
			raiserror(''ERROR. invalid template ID'', 18, 1)
			return(0)
		 end

		update ccTideWater_Templates set TempStatus=0 where Temp_id=@Temp_id
		return(0)
	 end

	if @Type=3 -- update
	 begin
		if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
		 begin
			raiserror(''ERROR. invalid template ID'', 18, 1) 
			return(0)
		 end 

		begin tran upd
		update ccTideWater_Templates set 
		 Temp_Desc=isnull(@Temp_Desc,Temp_Desc),
		 ConnString=isnull(@ConnString,ConnString),
		 PathFile=isnull(@PathFile,PathFile),
		 User_id=isnull(@User_id,User_id),
		 cam_id=isnull(@cam_id,cam_id),
		 TableName=isnull(@TableName,TableName),
		 Tipo_Filtro=isnull(@Tipo_Filtro,Tipo_Filtro),
		 AceptaCel=isnull(@AceptaCel,AceptaCel),
		 tipo_Con=isnull(@tipo_Con,tipo_Con),
		 Where_Array=isnull(@Where_Array,Where_Array),
		 idtipolista_array=isnull(@idtipolista_array,idtipolista_array),
		 cal_Key_col=isnull(@cal_Key_col,cal_Key_col),

	--	 cal_telefono_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1) = ''''
	--	  then cal_telefono_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1) end,
	--
	--	 cal_telefono2_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2) = ''''
	--	  then cal_telefono2_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2) end,
	--
	--	 cal_telefono3_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3) = ''''
	--	  then cal_telefono3_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3) end,
	--
	--	 cal_telefono4_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4) = ''''
	--	  then cal_telefono4_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4) end,
	--
	--	 cal_telefono5_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5) = ''''
	--	  then cal_telefono5_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5) end,

		 cal_telefono_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1),
		 cal_telefono2_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2),
		 cal_telefono3_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3),
		 cal_telefono4_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4),
		 cal_telefono5_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5),

		 cal_callback_col=isnull(@cal_callback_col,cal_callback_col),

		hasHeader = isnull(@hasHeader,hasHeader),
		nameList = isnull(@nameList,nameList)
		where Temp_id=@Temp_id
	 
		if @@Rowcount<0	 
		 begin
			raiserror(''ERROR. update can not be reached'', 18, 2) 
			return(0)
		 end 

		if isnull(@ColumnAssigned,''&'')<>''&''
		 begin
			update ccTideWater_Templates_Cols set ccTideWater_Templates_Cols.ColumnAssigned=S.value 
			from ccodatos D join dbo.fn_RIASplitDelimited(@ColumnAssigned, '','') S on D.id=S.id 
			where /*isnull(S.value,'''')<>'''' and*/ ccTideWater_Templates_Cols.Temp_id=@Temp_id and S.id=ccTideWater_Templates_Cols.id

			if @@ROWCOUNT=0
			 begin
				raiserror(''ERROR. update 2 can not be reached'', 18, 1) 
				rollback tran upd
				return(0)
			 end
		 end

		commit tran upd
		return(0)
	 end

	set nocount off'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccspAgent_GetLastCalls'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspAgent_GetLastCalls'')
		begin
			DROP PROCEDURE ccspAgent_GetLastCalls;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccspAgent_GetLastCalls'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
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
		  cal_key      VARCHAR(40), 
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
			END'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccspGalateaINInsertaCallBack'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspGalateaINInsertaCallBack'')
		begin
			DROP PROCEDURE ccspGalateaINInsertaCallBack;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccspGalateaINInsertaCallBack'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspGalateaINInsertaCallBack] 
		@cal_key       VARCHAR(40)  = '''', 
		@acd_id        SMALLINT, 
		@cal_telefono  VARCHAR(19), 
		@fechadial     VARCHAR(17), 
		@dato1         VARCHAR(255), 
		@dato2         VARCHAR(255), 
		@dato3         VARCHAR(255), 
		@dato4         VARCHAR(255), 
		@dato5         VARCHAR(255), 
		@TelReprograma SMALLINT     = -1, 
		@user_id       INT          = 0, 
		@isAuto        BIT          = 0
	AS
		BEGIN
			SET NOCOUNT ON;
			DECLARE @cam_id SMALLINT;
			SELECT @cam_id = ISNULL(cam_id, 0)
			FROM ccinbound
			WHERE Inbound_id = @acd_id;
			EXEC ccsp_INInsertaCallBack 
				 @cal_key, 
				 @cam_id, 
				 @cal_telefono, 
				 @fechadial, 
				 @dato1, 
				 @dato2, 
				 @dato3, 
				 @dato4, 
				 @dato5, 
				 @TelReprograma, 
				 @user_id, 
				 @isAuto;
			SET NOCOUNT OFF;
		END;'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccspGenDetCall'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspGenDetCall'')
		begin
			DROP PROCEDURE ccspGenDetCall;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccspGenDetCall'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspGenDetCall]
	@tipo as integer
	AS

	SET NOCOUNT ON

	declare @server varchar(200)
	declare @sql  varchar(8000)
	declare @from datetime
	declare @to datetime

	select @server = valor from ccsettings where setting_id = 22

	set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '':00'',121)
	set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '':00'',121)

	SET ARITHABORT ON

	if @tipo = 0
	begin

	-- Borra tabla destino
	set @sql = ''DELETE ''+@server+''.dbo.ccocallsout WHERE cal_inicio >= ''+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +'' AND cal_inicio < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	--exec (@sql)

	set @sql = ''insert into '' + @server +''.dbo.ccocallsout (cal_id,callout_id, cal_telefono, cal_puerto,cam_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,cal_tlinebusy,costo,provedor_id,tipollamada_id) ''
	set @sql = @sql + ''select cal_id,callout_id, cal_telefono, cal_puerto,cam_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,cal_tlinebusy,costo,provedor_id,tipollamada_id from ccocallsout WHERE cal_id > (select isnull(max(cal_id),1) from '' + @server +''.dbo.ccocallsout) and cal_id<= (select min(cal_id) from ccocallsout with(index (IX_ccoCallsOut_2)) where cal_inicio > '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '')''
	--print @sql
	exec(@sql)

	-- Borra tabla destino
	set @sql = ''DELETE ''+@server+''.dbo.cccallsin WHERE cal_inicio >= ''+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +'' AND cal_inicio < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	--exec (@sql)

	set @sql = ''insert into '' + @server +''.dbo.cccallsin (cal_id,dni_id, cal_ani, cal_puerto,inbound_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_twait,cal_txfer,cal_tcall,cal_tring,cal_xfer,cal_inicio,cal_opciones,cal_origin_id) ''
	set @sql = @sql + ''select cal_id,dni_id, cal_ani, cal_puerto,inbound_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_twait,cal_txfer,cal_tcall,cal_tring,cal_xfer,cal_inicio,cal_opciones,cal_origin_id from cccallsin WHERE cal_id > (select isnull(max(cal_id),1) from '' + @server +''.dbo.cccallsin) and cal_id<= (select min(cal_id) from cccallsin with(index (IX_ccCallsIn)) where cal_inicio > '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '')''
	--print @sql
	exec(@sql)

	-- Borra tabla destino
	set @sql = ''DELETE ''+@server+''.dbo.ccLogAgentesNotReady WHERE fecha >= ''+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +'' AND fecha < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	--exec (@sql)

	set @sql = ''insert into '' + @server +''.dbo.ccLogAgentesNotReady (user_id,tiponotready_id,tStatus,fecha,separado) ''
	set @sql = @sql + ''select user_id,tiponotready_id,tStatus,fecha,separado from ccLogAgentesNotReady where fecha >= (select max(fecha) from '' + @server +''.dbo.ccLogAgentesNotReady) AND fecha < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	exec(@sql)

	-- Borra tabla destino
	set @sql = ''DELETE ''+@server+''.dbo.ccologdials WHERE fecha >= ''+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +'' AND fecha < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	--exec (@sql)

	set @sql = ''insert into '' + @server +''.dbo.ccologdials (logdial_id,callout_id,cam_id,tiporesdial_id,telefono,puerto,fecha,tdialing,tbusy,answerbit) ''
	set @sql = @sql + ''select logdial_id,callout_id,cam_id,tiporesdial_id,telefono,puerto,fecha,tdialing,tbusy,answerbit from ccologdials where logDial_ID > (select isnull(max(logDial_ID),0) from '' + @server +''.dbo.ccoLogDials)AND logDial_ID <= (select min(logDial_ID) from ccoLogDials with(index (IX_ccoLogDials)) where fecha > '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '')''
	--print @sql
	exec(@sql)

	-- Borra tabla destino
	set @sql = ''DELETE ''+@server+''.dbo.ccoCallsOutSource WHERE cal_fechadial >= ''+ char(0x27) + convert(varchar(20),@from,120) + char(0x27) +'' AND cal_fechadial < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	--exec (@sql)

	set @sql = ''insert into '' + @server +''.dbo.ccoCallsOutSource (callout_id,cal_key,cam_id,cal_fechaDial) ''
	set @sql = @sql + ''select callout_id,cal_key,cam_id,cal_fechaDial from ccoCallsOutSource where callout_id > (select max(callout_id) from '' + @server +''.dbo.ccocallsoutsource) AND cal_fechadial < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	exec(@sql)

	end

	if @tipo = 1
	begin

	set @from = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''06:00:00'',121)
	set @to = convert(smalldatetime,convert(varchar(11),getdate(),121)+ ''23:00:00'',121)


	set @sql = ''Update rept set rept.calif_id = cc.calif_id, rept.cal_tdialog = cc.cal_tdialog from '' + @server +''.dbo.ccocallsout rept, ccocallsout cc where rept.cal_tdialog = 0 and rept.cal_inicio >= '' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + '' and rept.cal_inicio < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '' and rept.user_id <> 0 and rept.calif_id = 0 and rept.cal_manual <> 1 and rept.user_id = cc.user_id and rept.cal_id = cc.cal_id''
	--print @sql
	exec(@sql)


	set @sql = ''Update rept set rept.calif_id = cc.calif_id, rept.cal_tdialog = cc.cal_tdialog from '' + @server +''.dbo.cccallsin rept, cccallsin cc where rept.cal_tdialog = 0 and rept.cal_inicio >= '' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + '' and rept.cal_inicio < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '' and rept.user_id <> 0 and rept.calif_id = 0 and rept.user_id = cc.user_id and rept.cal_id = cc.cal_id''
	--print @sql
	exec(@sql)

	set @sql = ''update rept set rept.tstatus = cc.tstatus from '' + @server +''.dbo.cclogagentesNotReady rept, cclogagentesnotready cc where rept.tstatus = 0 and rept.fecha >= '' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + '' and rept.fecha < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '' and rept.user_id = cc.user_id and rept.tiponotready_id = cc.tiponotready_id and rept.fecha = cc.fecha''
	--print @sql
	exec(@sql)

	set @sql = ''Update rept set rept.tdialing = cc.tdialing from '' + @server +''.dbo.ccologdials rept, ccologdials cc where cc.logdial_id = rept.logdial_id and rept.tdialing = 0 and rept.fecha >= '' + char(0x27) +  convert(varchar(20),@from,120) + char(0x27) + '' and rept.fecha < '' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
	--print @sql
	exec(@sql)

	end
	'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP ccsp_PhoneInBL'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_PhoneInBL'')
		begin
			DROP PROCEDURE ccsp_PhoneInBL;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccsp_PhoneInBL'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_PhoneInBL]
	@action as tinyint,
	@cam_id as smallint,
	@telefono as varchar(20),
	@cal_key as varchar(40) = null
	AS
	if @action = 1 begin	
		if (select dbo.ValidateBlackListPhone(@telefono,@cam_id,@cal_key)) = 1 begin
			select 1 as IsBlackList
		end
		else begin
			select 0 as IsBlackList
		end
	end'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP oldccsp_DLRSaveDialResult'
	set @sql = 'if exists (select * from sys.procedures where name = N''oldccsp_DLRSaveDialResult'')
		begin
			DROP PROCEDURE oldccsp_DLRSaveDialResult;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP oldccsp_DLRSaveDialResult'
	set @sql = 'CREATE procedure [dbo].[oldccsp_DLRSaveDialResult]
						@callout_id int,
						@cam_id smallint,
						@tipoResDial_id tinyint,
						@Telefono varchar(30),
						@Puerto smallint,
						@tDialing tinyint=0,
						@tBusy smallint=0,
						@call_id int = 0,
						@answerbit bit = null,
						@tAnswerBit smallint = 0,
						@canceledNoAgents bit =0,
						@disconnectCause varchar(250) = '''',
						@cal_key varchar(40) = ''''
						AS
						set nocount on
						declare @tNow as datetime, @RecicleSIC tinyint
						declare @logDial_id int
						declare @tAnswerBitFinal as datetime

						SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
						select @tNow=getdate()

						select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)

						if @call_id > 0 and @tipoResDial_id = 1
						BEGIN
							INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
							select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
						END
						ELSE
						BEGIN
							INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
							select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
						END

						select @logDial_id=scope_identity()

						if (@RecicleSIC=1)
						 begin
							UPDATE ccoWorkingTable SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
						 end

						select @logDial_id

						-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
						if @call_id > 0 and @tipoResDial_id = 1
						begin
							update ccoCallsOut set cal_manual = 2, cal_puerto = @Puerto	where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
							exec ccsp_CstoCalculaCosto @call_id

							if @cal_key ='''' begin
								select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
								update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
							end

						end

						-- inserta informacion para reportes de workgroup
						insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
						select IDWG, @logDial_id, IdCampEsp, getdate() 
						from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

						-- Guarda configuracion de TipoDialingMode
						update ccoLogDials set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
						set nocount off'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP xx_Elimina'
	set @sql = 'if exists (select * from sys.procedures where name = N''xx_Elimina'')
		begin
			DROP PROCEDURE xx_Elimina;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP xx_Elimina'
	set @sql = 'CREATE PROCEDURE [dbo].[xx_Elimina] @cal_key VARCHAR(40), 
										@cam_id  INTEGER
	AS
		 DELETE ccoWorkingTable
		 WHERE cal_keyw = @cal_key
			   AND cam_id = @cam_id
			   AND cal_status IN(0, 1);'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP xx_Inserta'
	set @sql = 'if exists (select * from sys.procedures where name = N''xx_Inserta'')
		begin
			DROP PROCEDURE xx_Inserta;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP xx_Inserta'
	set @sql = 'CREATE PROCEDURE [dbo].[xx_Inserta] @cal_key       VARCHAR(40), 
										@cal_telefono  VARCHAR(19), 
										@cal_telefono2 VARCHAR(19), 
										@cal_telefono3 VARCHAR(19), 
										@cal_telefono4 VARCHAR(19), 
										@cal_telefono5 VARCHAR(19), 
										@dato1         VARCHAR(255), 
										@dato2         VARCHAR(255), 
										@dato3         VARCHAR(255), 
										@dato4         VARCHAR(255), 
										@dato5         VARCHAR(255), 
										@cam_id        INTEGER, 
										@FCallBack     SMALLDATETIME = '''', 
										@cal_status    TINYINT       = 0, 
										@User_id       INTEGER       = 0
	AS
		 DECLARE @calloutid INT;
		 IF(@cal_status = 0)
			 SET @FCallBack = GETDATE();
		 INSERT INTO ccoCallsOutSource
		 (cal_key, 
		  cal_telefono, 
		  cal_telefono2, 
		  cal_telefono3, 
		  cal_telefono4, 
		  cal_telefono5, 
		  dato1, 
		  dato2, 
		  dato3, 
		  dato4, 
		  dato5, 
		  cam_id, 
		  cal_fechaDial, 
		  cal_status, 
		  user_id
		 )
		 VALUES
		 (@cal_key, 
		  @cal_telefono, 
		  @cal_telefono2, 
		  @cal_telefono3, 
		  @cal_telefono4, 
		  @cal_telefono5, 
		  @dato1, 
		  @dato2, 
		  @dato3, 
		  @dato4, 
		  @dato5, 
		  @cam_id, 
		  @FCallBack, 
		  @cal_status, 
		  @User_id
		 );
		 SELECT @calloutid = SCOPE_IDENTITY();
		 INSERT INTO xxClienteHistorial
		 (callout_id, 
		  fechaAct
		 )
		 VALUES
		 (@calloutid, 
		  GETDATE()
		 );
		 SELECT @calloutid;'
	EXEC(@sql)

	set @process = 'CW-4384 DROP SP xx_Inserta_old'
	set @sql = 'if exists (select * from sys.procedures where name = N''xx_Inserta_old'')
		begin
			DROP PROCEDURE xx_Inserta_old;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP xx_Inserta_old'
	set @sql = 'CREATE PROCEDURE [dbo].[xx_Inserta_old] @cal_key       VARCHAR(40), 
											@cal_telefono  VARCHAR(19), 
											@cal_telefono2 VARCHAR(19), 
											@cal_telefono3 VARCHAR(19), 
											@cal_telefono4 VARCHAR(19), 
											@cal_telefono5 VARCHAR(19), 
											@dato1         VARCHAR(255), 
											@dato2         VARCHAR(255), 
											@dato3         VARCHAR(255), 
											@dato4         VARCHAR(255), 
											@dato5         VARCHAR(255), 
											@cam_id        INTEGER, 
											@FCallBack     SMALLDATETIME = '''', 
											@cal_status    TINYINT       = 0, 
											@User_id       INTEGER       = 0
	AS
		 DECLARE @calloutid INT;
		 IF(@cal_status = 0)
			 SET @FCallBack = GETDATE();
		 INSERT INTO ccoCallsOutSource
		 (cal_key, 
		  cal_telefono, 
		  cal_telefono2, 
		  cal_telefono3, 
		  cal_telefono4, 
		  cal_telefono5, 
		  dato1, 
		  dato2, 
		  dato3, 
		  dato4, 
		  dato5, 
		  cam_id, 
		  cal_fechaDial, 
		  cal_status, 
		  user_id
		 )
		 VALUES
		 (@cal_key, 
		  @cal_telefono, 
		  @cal_telefono2, 
		  @cal_telefono3, 
		  @cal_telefono4, 
		  @cal_telefono5, 
		  @dato1, 
		  @dato2, 
		  @dato3, 
		  @dato4, 
		  @dato5, 
		  @cam_id, 
		  @FCallBack, 
		  @cal_status, 
		  @User_id
		 );
		 SELECT @calloutid = SCOPE_IDENTITY();
		 INSERT INTO xxClienteHistorial
		 (callout_id, 
		  fechaAct
		 )
		 VALUES
		 (@calloutid, 
		  GETDATE()
		 );
		 SELECT @calloutid;'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP'
	set @sql = ''
	EXEC(@sql)

	set @process = 'CW-5225 EOMC Check if exists ccsp_GalateaAdminBlackListDispositions'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlackListDispositions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminBlackListDispositions;
            end'
    EXEC(@sql)

set @process = 'CW-5225 EOMC Create ccsp_GalateaAdminBlackListDispositions'	
	set @sql = 'CREATE procedure ccsp_GalateaAdminBlackListDispositions-- guiandose del sp ccsp_RIAcalifblacklist de xion
@Option tinyint,
@BlackListIds_ToProcess varchar(1500) = '''',
@CampType tinyint = 1, -- 1 Campaña SALIDA, 0 Campaña ENTRADA
@Qualif_id int = null

as
set nocount on
declare @sql nvarchar(max)

if @Option = 1 -- Muestra listas negras asignadas a calificaciones de Campañas
 begin
	select b.idtipolista as BlackListId, a.calif_id as DispositionId
	from cccalifblacklist a with(index(IX_cccalifblacklist)) join ccTiposListaNegra b on a.idtipolista = b.idtipolista
	where a.tipo = @CampType 
	group by a.calif_id, b.idtipolista
	return(0)
 end

else if @Option = 2 -- Inserta BlackList por calificacion 
begin
	if LEN(@BlackListIds_ToProcess)>0 
		begin
			insert into cccalifblacklist(calif_id,idTipoLista,tipo)
			select  @Qualif_id calif_id,B.Value idTipolista, @CampType tipo from dbo.fn_RIASplitDelimited (@BlackListIds_ToProcess, '','') B
			left join  cccalifblacklist A on A.idTipoLista=B.value and A.tipo=@CampType and A.calif_id=@Qualif_id
			where A.idTipoLista is null
		end
	return(0)
end
else if @Option = 3 -- Elimina BlackList por calificacion Campañas
begin
	if LEN(@BlackListIds_ToProcess)>0 
		begin
			set @sql= ''delete from cccalifblacklist where tipo ='' + cast(@CampType  as varchar(10)) + '' and idTipoLista in(''+@BlackListIds_ToProcess+'') and calif_id='' + cast(@Qualif_id  as varchar(10))
			exec(@sql)
		end
	return(0)
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
