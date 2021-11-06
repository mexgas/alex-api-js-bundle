CREATE PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
	@option TINYINT,
	@loginLst VARCHAR(max) = NULL,
	@moduleWithOperation varchar(max) = NULL,
	@operationDateIni SMALLDATETIME = NULL,
	@operationDateFin SMALLDATETIME = NULL,
	@top INT = 0
	AS
	SET NOCOUNT ON

	DECLARE @lang TINYINT

	SELECT @lang = valor
	FROM ccsettings
	WHERE setting_id = 27

	IF @option = 1 -- Catalogo de modulos
	BEGIN
		WITH Catalog AS(
		SELECT cast(m.module_id as int) module_id, cast(o.operationType as int) operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX('|', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX('|', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX('|', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX('|', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
		FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
		JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
		JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id

		UNION

		SELECT 0, - 1, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END, ' - '

		UNION

		SELECT 0, 0, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END

		UNION

		SELECT cast(module_id as int) module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX('|', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX('|', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN ' - TODAS - ' ELSE ' - ALL - ' END
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))

		UNION

		SELECT cast(module_id as int) module_id, - 1 , CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX('|', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX('|', descripcion) + 1, len(descripcion)) END AS descripcion, ' - '
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module)))

		SELECT module_id,operationType,mDescripcion,oDescripcion FROM Catalog
		WHERE module_id not in(5,8,14,21,22,25,32,33,36,37,44,53,57,58,59,60,42)
		AND operationType not in(6,15,51,58,36,46,44,45,59,12,8,7,55,54,33)
		ORDER BY mDescripcion, oDescripcion

		RETURN (0)
	END

	IF @option = 2 -- Muestra informacion por filtros
	BEGIN

		declare @sql as nvarchar(max)
		DECLARE @table TABLE(id int,value varchar(max))
		declare @id int
		declare @moduleId varchar(max)
		declare @operationLst varchar(max)
		declare @query varchar(max) = ' and ('
		declare @value varchar(max)
		declare @first int = 1
		declare @pos int

		insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'') as varchar(max)), ',')
		while exists(select * from @table)
		begin
			select top 1 @id = id, @value = value from @table
			set @pos = charindex(':', @value)
			if(@pos <> 0)
			begin
				set @moduleId = substring(@value, 1, @pos-1)
				set @operationLst = replace(substring(@value, @pos+1, len(@value)), '-', ',')
				if(@first = 1)
				begin
					set @query = @query + 'l.module_id=' + @moduleId + ' and l.operationType in (' + @operationLst + ')'
					set @first = 0
				end
				else
				begin
					set @query = @query + ' or l.module_id=' + @moduleId + ' and l.operationType in (' + @operationLst + ')'
				end
			end

			delete @table where id = @id
		end
		set @query = @query + ')'


		SET ROWCOUNT @top

		set @sql =
		'DECLARE @tableLogin TABLE(id int,value varchar(255))
		insert into @tableLogin  select * from dbo.fn_RIASplitDelimited(''' + cast(isnull(@loginLst,'') as varchar(max)) + ''','','')

		SELECT L.log_id, L.areaName, L.operationDate,
		CASE ' + cast(@lang as varchar(5)) + ' WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END operationType,
		L.LOGIN,
		CASE ' + cast(@lang as varchar(5)) + ' WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END module_id,
		CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE ' + cast(@lang as varchar(5)) + ' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
		CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE ' + cast(@lang as varchar(5)) + ' WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
		FROM CCRIALOG L
		JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
		JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
		LEFT JOIN targetRecord t ON t.targetT = L.target
		LEFT JOIN valueRecord v ON v.valueT = L.value
		WHERE 1=1 '
		+
		case isnull(@loginLst, '') when '' then '' else
		' AND L.LOGIN in (select value from @tableLogin) '
		END
		+
		case isnull(@moduleWithOperation, '') when '' then '' else
		@query
		end
		+ case ISNULL(@operationDateIni, '') when '' then '' else
		'AND L.operationDate >= CASE WHEN isnull('''+ convert(varchar(19), @operationDateIni, 121) + ''', '' 19000101 '') <> '' 19000101 '' AND isnull(''' + convert(varchar(19), @operationDateFin, 121) + ''', '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, -1, ''' + convert(varchar(19), @operationDateIni, 121) + ''') ELSE L.operationDate END '
		+ ' AND L.operationDate <= CASE WHEN isnull('''+ convert(varchar(19), @operationDateIni, 121) + ''', '' 19000101 '') <> '' 19000101 '' AND isnull('''+ convert(varchar(19), @operationDateFin, 121) + ''', '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, 1, ''' + convert(varchar(19), @operationDateFin, 121) + ''') ELSE L.operationDate END'
		end
		+
		' ORDER BY L.operationDate DESC'
		execute sp_executesql @sql
		--print @sql
	END


	SET NOCOUNT OFF