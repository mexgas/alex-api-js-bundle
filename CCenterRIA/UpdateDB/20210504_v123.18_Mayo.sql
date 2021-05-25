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


	set @process = 'CW-5084 Desactivar la validación de teléfono en llamada manual'	
	set @sql = 'UPDATE CCSETTINGs SET detalle =  ''0 - Realiza las validaciones de marcacion normalmente / 1 - marca el numero sin validarlo / 2 Valida solo lista negra'' WHERE SETTING_id = 206'
    EXEC(@sql)

	set @process = 'CW-5084 Desactivar la validación de teléfono en llamada manual'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Limpia'')
            begin
          DROP PROCEDURE ccsp_Limpia;
            end'
    EXEC(@sql)
	
	set @process = 'CW-5084 Desactivar la validación de teléfono en llamada manual'	
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
	BEGIN -- Setting 108 validar el tamaño longitud del telefono
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
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama 
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

	set @process = 'CW-4384 Alter colum Database '
	set @sql = 'if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccoCallsOutSource'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccoCallsOutSource ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END


	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccoWorkingTable'' and COL.name = ''cal_Keyw'') < 40
	Begin
		ALTER TABLE ccoWorkingTable ALTER COLUMN cal_Keyw VARCHAR (40) NOT NULL
	End

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccBorrardasReciclaje'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccBorrardasReciclaje ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccCallsIn'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccCallsIn ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccgenTelMarcados'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccgenTelMarcados ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccoCallBacks'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccoCallBacks ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccoCallsOut'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccoCallsOut ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccoLogDials'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccoLogDials ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccRIAClienteCarga'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccRIAClienteCarga ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccUploadTemporal'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccUploadTemporal ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''ccTideWater_Templates'' and COL.name = ''cal_Key_col'') < 40
	BEGIN
		ALTER TABLE ccTideWater_Templates ALTER COLUMN cal_Key_col VARCHAR (40) NOT NULL
	END'
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

	set @process = 'Se elimina sp si existe'	
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminCampaigns;
    end
	'
	EXEC(@sql)


    set @process = 'CW-5268 Se creo la consulta para obtener los datos de los agentes por campaña'	
	set @sql = '
    CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
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
                                a.AreaName AS Area,
                                inb.chat AS InboundType
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

    IF @Option = 4   -- Update Pin from Campaign per Admin
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
            
    IF @Option = 5   -- Get Pin from Campaign Ids per Admin
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

    IF @Option = 6   -- Get Blacklist Ids by Campaign Id
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

    IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
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

    IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
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

    IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
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
    IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type 
        BEGIN
            DECLARE @date datetime = CONVERT(DATE, DATEADD(hh, -3, GETDATE()))
            DECLARE @Wg TABLE(id INT, PRIMARY KEY(id));
            DECLARE @tmpAgent TABLE(id INT, PRIMARY KEY(id));
            DECLARE @tmpCamAgent TABLE(camId INT, userId INT, PRIMARY KEY( camId, userId ));
            DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
            DECLARE @AgentStatusWithTotals TABLE(CampName VARCHAR(MAX), Total INT, Ready INT, NotReady INT, Dialog INT, Area VARCHAR(MAX));

			INSERT INTO @Wg
					SELECT DISTINCT IDWG FROM ccRIAWorkGroupUsers WHERE user_id = @AdminId;

            INSERT INTO @tmpAgent
                    SELECT DISTINCT  A.User_id FROM ccRIAWorkGroupUsers A
                    INNER JOIN @Wg B ON A.IDWG=B.id
                    INNER JOIN ccUsers C ON A.User_id=C.User_id AND C.TipoUser_id=1  
                    ORDER BY A.User_id;

            INSERT INTO @tmpCamAgent
                    SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id FROM ccRIACampEspWG campPerWg
                    INNER JOIN @Wg wg ON wg.Id=campPerWg.IDWG
                    INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG=wg.id 
                    INNER JOIN ccUsers C ON wgUser.User_id=C.User_id AND C.TipoUser_id=1
                    WHERE campPerWg.Tipo = @CampType;

            WITH lastState
                    AS ( SELECT A.user_id,  MAX( A.fecha ) AS fecha
                        FROM ccLogAgentesDia A
                        INNER JOIN @tmpAgent B ON A.User_id=B.id
                        WHERE fecha>= @date
                        GROUP BY user_id )


                    INSERT INTO @AgentStatus
                        SELECT A.camId,  A.userId, 
                        ISNULL( B.currentStatus, 0 ) currentStatus,
                        CASE WHEN B.IdCampEsp=A.camId AND B.Tipo = @CampType AND B.currentStatus IN( 4, 5, 6, 9 ) THEN 1 ELSE NULL END AS isCampDialog
                        FROM @tmpCamAgent A
                        LEFT JOIN
                        (
                            SELECT B.User_id, 
                                    B.currentStatus, 
                                    B.IdCampEsp, 
                                    B.Tipo
                            FROM lastState A
                            INNER JOIN
                            ccLogAgentesDia B
                            ON A.User_id=B.User_id
                                AND A.fecha=B.fecha
                        ) B
                        ON A.userId=B.User_id;

            IF @CampType = 1
                BEGIN
					IF @Id <> 0
						INSERT INTO @AgentStatusWithTotals
						SELECT  B.cam_descripcion,
								COUNT( CurrentState ) as total,
								COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready, 
								COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END) 
								+ count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                            
								as notReady,
								COUNT( isCampDialog ) as dialog,  
								C.AreaName
						FROM @AgentStatus A
						INNER JOIN ccCamps B on A.CampId=B.cam_id
						INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						WHERE A.CampId = @Id
						GROUP BY B.cam_descripcion, CampId, C.AreaName
					ELSE
						INSERT INTO @AgentStatusWithTotals
						SELECT  B.cam_descripcion,
								COUNT( CurrentState ) as total,
								COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready, 
								COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END) 
								+ count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                            
								as notReady,
								COUNT( isCampDialog ) as dialog,  
								C.AreaName
						FROM @AgentStatus A
						INNER JOIN ccCamps B on A.CampId=B.cam_id
						INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						GROUP BY B.cam_descripcion, CampId, C.AreaName
                END 
            ELSE 
                BEGIN 
					IF @Id <> 0
						INSERT INTO @AgentStatusWithTotals
						SELECT  B.descripcion,
								COUNT( CurrentState ),
								COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ), 
								COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
								+ count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
								,
								COUNT( isCampDialog ), 
								C.AreaName
						FROM @AgentStatus A
						INNER JOIN ccInbound B on A.CampId = B.Inbound_id  
						INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						WHERE A.CampId = @Id
						GROUP BY  B.descripcion, CampId , C.AreaName
					ELSE
						INSERT INTO @AgentStatusWithTotals
						SELECT  B.descripcion,
								COUNT( CurrentState ),
								COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ), 
								COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
								+ count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
								,
								COUNT( isCampDialog ), 
								C.AreaName
						FROM @AgentStatus A
						INNER JOIN ccInbound B on A.CampId = B.Inbound_id  
						INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						GROUP BY  B.descripcion, CampId , C.AreaName
                END 
                     
                    
            SELECT * FROM @AgentStatusWithTotals
        END;

    END'
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
	
		set @process = 'Check if exists configuraIdiomaCatalogosEspañol'	
	set @sql = 'if exists (select * from sys.procedures where name = N''configuraIdiomaCatalogosEspañol'')
            begin
          DROP PROCEDURE configuraIdiomaCatalogosEspañol;
            end'
    EXEC(@sql)


	set @process = 'Se crea sp configuraIdiomaCatalogosEspañol'
	set @sql = 'Create PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol]
AS

Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [dbo].[ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
truncate table [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
delete from [dbo].[ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from [dbo].cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes voz defualt''
DELETE [dbo].[ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')
	'
    EXEC(@sql)
	
	
	set @process = 'Check if exists configuraIdiomaCatalogosEnglish'	
	set @sql = 'if exists (select * from sys.procedures where name = N''configuraIdiomaCatalogosEnglish'')
            begin
          DROP PROCEDURE configuraIdiomaCatalogosEnglish;
            end'
    EXEC(@sql)


	set @process = 'Se crea sp configuraIdiomaCatalogosEnglish'
	set @sql = 'CREATE PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Other'')


DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
delete from [ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Xfer Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Ringing Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')


Print ''Estableciendo los tipos de usuario''
Delete [ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

Print ''Mensajes default chat''
DELETE [ccRIAChatInboundMsgs]
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')
	'
    EXEC(@sql)
	
	set @process = 'CW-5288 EOMC DROP SP ccsp_GalateaAdminBlackListACD'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlackListACD'')
		begin
			DROP PROCEDURE ccsp_GalateaAdminBlackListACD;
		end'
	EXEC(@sql)


	set @process = 'CW-5288 EOMC CREATE SP ccsp_GalateaAdminBlackListACD'
	set @sql = 'CREATE PROCEDURE ccsp_GalateaAdminBlackListACD-- Guiandose del sp ccsp_RIABlackListACD
@Type smallint,
@InboundID SmallInt = 0,
@InsertSchedule_id varchar(max),
@DeleteSchedule_id varchar(max),
@ManyInboundIDs varchar(max)=''''

as
set nocount on

if @Type = 2 -- Relacion many ACDs with all BLists
 begin
	select cl.inbound_id as CampId, ca.descripcion as CampName, cl.idtipolista as BlacklistId , tl.Tipolista as BlacklistName
	from ACDlistanegra cl join ccInbound ca on cl.inbound_id = ca.inbound_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1  and  cl.inbound_id in (select value from dbo.fn_RIASplitDelimited(@ManyInboundIDs, '',''))
	order by 1, 3
	return(0)
 end

if @Type = 3 -- Relacion only one ACD with BLists
 begin
	select cl.inbound_id as CampId, ca.descripcion as CampName, cl.idtipolista as BlacklistId , tl.Tipolista as BlacklistName
	from ACDlistanegra cl join ccInbound ca on cl.inbound_id = ca.inbound_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1  and cl.inbound_id = @InboundID
	order by 1, 3
	return(0)
 end

if @Type = 4 -- Asignar BList a ACD
 begin

	if @InboundID = 0
	 begin
		delete ACDlistanegra where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))
	
		insert into ACDlistanegra (idtipolista, Inbound_id, status)
		select FN.value, C.Inbound_id, 1 from ccInbound C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN 
		where C.Inbound_id not in (select CL.Inbound_id from ACDlistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN
		on CL.idtipolista = FN.value where CL.status = 1)
		return(0)
	 end

 	update ACDlistanegra set status = 1 where Inbound_id = @InboundID
	and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))
	
	insert into ACDlistanegra (idtipolista, Inbound_id, status)
	select value, @InboundID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') 
		where value not in (select idtipolista from ACDlistanegra where Inbound_id = @InboundID and status = 1
		and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')))
	return(0)
 end

if @Type = 5 -- Desasignar BList a ACD
 begin
	if @InboundID=0
	 begin
		update ACDlistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
		return(0)
	 end
 
	update ACDlistanegra set status = 0 where Inbound_id = @InboundID and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
	return(0)
 end

return(0)
'
	EXEC(@sql)	

	set @process = 'CW-5333 EOMC Alter sp ccsp_GalateaAdminBlackListCampout'	
	set @sql = '
ALTER PROCEDURE ccsp_GalateaAdminBlackListCampout-- basandose del sp ccsp_RIABlackListCamp
@Option smallint,
@IDArea smallint = 0,
@CamID SmallInt = 0,
@InsertSchedule_id varchar(max) = ''0'',
@DeleteSchedule_id varchar(max) = ''0'',
@ManyOutboundIDs varchar(max)=''''
as

if @Option = 1 -- Asignar listas negras a una campaña de salida
 begin

  if @CamID = 0
   begin
    update Camplistanegra set status = 1 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

    insert into Camplistanegra (idtipolista, cam_id, status)
    select FN.value, C.cam_id, 1 from ccCamps C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN where C.IDArea = @IDArea
    and C.cam_id not in (select CL.cam_id from Camplistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN
    on CL.idtipolista = FN.value where CL.status = 1)
    return(0)
   end

  update Camplistanegra set status = 1 where cam_id = @CamID
  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

  insert into Camplistanegra (idtipolista, cam_id, status)
  select value, @CamID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')
    where value not in (select idtipolista from Camplistanegra where cam_id = @CamID and status = 1
    and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')))

  Insert Into ccAgendaListaNegra (campsid,fecharegs,fechaaplicar) values (@CamID,''20100101'',getDate()) -- El 2010 es para que quite registros viejos con base en el cal fecha dial de ccocallsoutsource, principalmente para quitar callbacks de numeros cargados hace mucho tiempo

  declare @idAgenda as int
  select @idAgenda = SCOPE_IDENTITY()

  insert into ccAgenda_TipoListaNegra(idAgenda,idtipolista)
  select @idAgenda, value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')

  select DISTINCT idtipolista as BlacklistIdAssigned from Camplistanegra 
  where cam_id=@CamID and status=1 and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))
 end

if @Option = 2 -- Desasignar listas negras de la campaña de salida @CamID
 begin
  update Camplistanegra set status = 0 where cam_id = @CamID  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
  return(0)
 end

if @Option = 3 -- Desasignar listas negras de todas las campañas de salida a las que esten asignadas
 begin
 update Camplistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
  return(0)
 end

 if @Option = 4 -- trae las listas negras de la campaña de salida indicada en @CamID
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id = @CamID
  order by 1, 3
  return(0)
 end

  if @Option = 5 -- trae las relaciones entre listas negras y las campaña de salida indicadas en @ManyOutboundIDs
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id in(select value from dbo.fn_RIASplitDelimited(@ManyOutboundIDs, '',''))
  order by 1, 3
  return(0)
 end
'
    EXEC(@sql)
	

set @process = 'CW-5321 Servicio para recuperar la información de la campaña'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
            begin
          DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
            end'
    EXEC(@sql)

	
set @process = 'CW-5321 Servicio para recuperar la información de la campaña'	
	set @sql = 'CREATE PROCEDURE ccsp_GalateaGetOutboundConfiguration
@adminID int,
@campID int
AS
BEGIN

	declare @AllCampaigns table 
	(cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
	cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
	cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
	detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
	dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
	t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
	callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit, 
	callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint, 
	prefijo varchar(40),enbleprefix bit )
	 
	 INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID

	 SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
	 t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
	 ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
	 callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
	 prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
	 cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, cam_inter_cancelled CamInterCancelled,
	 cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
	 editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
	 compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd
	 from @AllCampaigns WHERE cam_id = @campID
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
