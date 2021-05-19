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
