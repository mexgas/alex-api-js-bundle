CREATE PROCEDURE [dbo].[ccsp_RIA_ABCLog] @optiON TINYINT, @areaName VARCHAR(50) = NULL, @operationType TINYINT = NULL, @login VARCHAR(20) = NULL, @moduleId INT = NULL, @value VARCHAR(250) = NULL, @target VARCHAR(250) = NULL, @operationDateIni SMALLDATETIME = NULL, @operationDateFin SMALLDATETIME = NULL, @top INT = 0
					AS
					SET NOCOUNT ON

					IF @option = 1 -- muestra todo
					BEGIN
						SELECT log_id, areaName, operationDate, operationType, LOGIN, module_id, value, target
						FROM ccRIALog WITH (NOLOCK)

						RETURN (0)
					END

					IF @option = 2 -- insert
					BEGIN
						DECLARE @areaNameValue AS VARCHAR(50)
						DECLARE @loginNameValue AS VARCHAR(50)

						SET @areaNameValue = isnull(@areaName,'')

						IF (left(@areaName, 1) = '!')
						BEGIN
							SELECT @areaNameValue = areaName
							FROM dbo.ccRIACat_Areas AS AREAS WITH (NOLOCK)
							WHERE AREAS.IDArea = right(@areaName, len(@areaName) - 1)
						END

						SET @loginNameValue = @login

						IF (left(@login, 1) = '!')
						BEGIN
							SELECT @loginNameValue = Login, 
							@areaNameValue = case datalength(@areaNameValue) when 0 then isnull(AreaName,'') else @areaNameValue end
							FROM ccUsers us (nolock) left join ccRIACat_Areas area (nolock) on area.IDArea=us.IDArea
							WHERE User_id = right(@login, len(@login) - 1)
						END

						INSERT INTO ccRIALog
						VALUES (@areaNameValue, GETDATE(), @operationType, @loginNameValue, @moduleId, @value, @target)

						RETURN (0)
					END

					DECLARE @lang TINYINT

					SELECT @lang = valor
					FROM ccsettings
					WHERE setting_id = 27

					IF @option = 3 -- muestra información por filtros (System>Log) // Fechas
					BEGIN
						SET ROWCOUNT @top

						SELECT L.log_id, L.areaName, L.operationDate, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX('|', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX('|', o.descripcion) + 1, len(o.descripcion)) END operationType, L.LOGIN, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX('|', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX('|', m.descripcion) + 1, len(m.descripcion)) END module_id, CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE @lang WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target, CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE @lang WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
						FROM CCRIALOG L
						JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
						JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
						LEFT JOIN targetRecord t ON t.targetT = L.target
						LEFT JOIN valueRecord v ON v.valueT = L.value
						WHERE L.operationType = CASE isnull(@operationType, 0) WHEN 0 THEN L.operationType ELSE @operationType END AND L.LOGIN = CASE isnull(@login, '') WHEN '' THEN L.LOGIN ELSE @login END AND L.module_id = CASE isnull(@moduleId, 0) WHEN 0 THEN L.module_id ELSE @moduleId END AND L.target = CASE isnull(@target, '') WHEN '' THEN L.target ELSE @target END AND L.operationDate >= CASE WHEN isnull(@operationDateIni, ' 19000101 ') <> ' 19000101 ' AND isnull(@operationDateFin, ' 19000101 ') <> ' 19000101 ' THEN dateadd(minute, - 1, @operationDateIni) ELSE L.operationDate END AND L.operationDate <= CASE WHEN isnull(@operationDateIni, ' 19000101 ') <> ' 19000101 ' AND isnull(@operationDateFin, ' 19000101 ') <> ' 19000101 ' THEN dateadd(minute, 1, @operationDateFin) ELSE L.operationDate END
						ORDER BY L.operationDate DESC

						RETURN (0)
					END

					IF @option = 4 -- Catalogo de modulos
					BEGIN
						SELECT m.module_id, o.operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX('|', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX('|', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX('|', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX('|', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
						FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
						JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
						JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id
						
						UNION
						
						SELECT 0, - 1, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END, ' - '
						
						UNION
						
						SELECT 0, 0, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END
						
						UNION
						
						SELECT module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX('|', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX('|', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END
						FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
						
						UNION
						
						SELECT module_id, - 1, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX('|', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX('|', descripcion) + 1, len(descripcion)) END AS descripcion, ' - '
						FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
						ORDER BY mDescripcion, oDescripcion

						RETURN (0)
					END

					IF @option = 5 -- Catalogo de operaciones
					BEGIN
						SELECT operationType, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX('|', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX('|', descripcion) + 1, len(descripcion)) END AS descripcion
						FROM ccRIALog_Operation WITH (INDEX (IX_ccRIALog_Operation))
						
						UNION
						
						SELECT 0, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END
						ORDER BY 2

						RETURN (0)
					END

					SET NOCOUNT OFF