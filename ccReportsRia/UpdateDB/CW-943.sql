/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Trejo
Date: 2018/03/20
Description:
**********************************************************************************************
CW-943 - Etiquetas en Portugués
**********************************************************************************************
Database: ccReportsRia
Required version: 50


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =50
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'CW-943 Etiquetas en Portugués GetReportMenus'
    	set @Sql= 'Alter PROCEDURE [dbo].[GetReportMenus]
--@userId = 10,@activeChat = 1,
--@activeAVRS = 1,
--@activeEmail =1,
--@activeTwitter =1
@userId int,
@activeChat tinyint,
@activeAVRS tinyint,
@activeCRM tinyint=0,
@activeEmail tinyint=0,
@activeTwitter tinyint=0
AS
BEGIN
select menu_id,
-- Se modificó la función substring para que muestre solo las etiquetas que se encuentran entre
-- los dos Pipes "|    |" 
-- En la primer linea se busca el primer "|" y busca hasta el final de la cadena
-- en la segunda linea quita los caracteres que ni pertenecen a lo seleccionado
	substring(menu_descrip, charindex(''|'', menu_descrip)+1, charindex(''|'', menu_descrip,
							charindex(''|'', menu_descrip)+1)-charindex(''|'', menu_descrip)-1)as menu_descrip,
	--substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
	nullif(parent,menu_id) as parent,Nivel,ordengral,release
	into #tempCCMenus
	from ccMenus with(nolock)
	where type = 3 and menu_id >= 2000 and(
		(menu_id not in (
		3130,3131,3132,3133,3134,3135,3136,
		8050,8060,8061,8062,8063,8070,8071,8072,8080,
		9000,9010,
		10000,10010,10020,10030,10040,
		11000,11010,11020,11030,11040
		))
		or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
		or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
		or  (@activeCRM = 1 and menu_id in (9000,9010) )
		or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
		or (@activeTwitter = 1 and menu_id in (11000,11010,11020,11030,11040))
		)
		order by menu_id
;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent,release)
AS
(
	select
		distinct b.Nivel as Nivel,
		b.menu_descrip as menu_descrip,
		b.menu_id as menu_id,
		b.ordengral as ordengral,
		b.parent as parent,b.release
		from #tempCCMenus as b
		inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
	UNION ALL
--RECURSIViDAD
	select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent,a.release
		from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
)
select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by menu_id
select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release from #tempCCMenusUser A
where  menu_id not in
	(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
order by menu_id
drop table #tempCCMenus
drop table #tempCCMenusUser
end'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués SaveReportTemplates'
    	set @Sql= 'ALTER PROCEDURE [dbo].[SaveReportTemplates] @userId int, @process int, @parameters varchar(max)
AS
BEGIN
DECLARE @reportName varchar(255)
DECLARE @id int
DECLARE @max int
DECLARE @idReport int
select @max = 10
if exists(select *
	from ccTemplates
	where user_Id = @userId)
begin
select @id = max(id) + 1
from ccTemplates
where user_Id = @userId
end
else
begin
select @id = 1
end
select @reportName = substring(menu_descrip, charindex(''|'', menu_descrip)+1, charindex(''|'', menu_descrip,
				charindex(''|'', menu_descrip)+1)-charindex(''|'', menu_descrip)-1)
--substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip))
from ccMenus
where menu_id = @process
if not exists (select * from ccTemplates where user_Id = @userId and reportName = @reportName)
begin
if (@id <= @max)
	begin
		update ccTemplates
		set id = id + 1
		where user_Id = @userId
		insert into ccTemplates
		values (1, @userId, replace(@parameters,'','',''|''), @reportName, getdate())
	end
else
	begin
		delete ccTemplates
		where user_Id = @userId
		and id = @max
		update ccTemplates
		set id = id + 1
		where user_Id = @userId
		insert into ccTemplates
		values (1, @userId, replace(@parameters,'','',''|''), @reportName, getdate())
	end
end
else
begin
select @idReport = id
from cctemplates
where user_Id = @userId
and reportName = @reportName
update cctemplates
set id = id + 1
where id < @idReport
update cctemplates
set id = 1, parameters = replace(@parameters,'','',''|''), date = GETDATE()
where user_Id = @userId
and reportName = @reportName
end
select 0
END'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
declare @idioma as tinyint
select @idioma = valor from ccSettings where setting_id=23
if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()	
if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSupervisor 
DELETE FROM dbo.RepAVRSSupervisor with(rowlock) 
where date >= @from AND date < @to
INSERT INTO dbo.RepAVRSSupervisor
--By Supervisor
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	f.total_forma AS scores, 
	f.total_forma AS scores, 
	f.total_forma AS scores,
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_formato,
	k.nombre,		
	f.id_grabacion,
	(case f.tipo 
		when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' WHEN @idioma = 2 THEN ''Gravações'' ELSE ''Recordings'' END 
		when ''2'' then ''Chat''
	end) as Medio,	
	f.cam_id as CamId,
	f.tipo_llamada as TipoLlamada,	
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,		 
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
from dbo.RIA_FORMACALIF f
INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1
							GROUP BY id_formato,nombre) as t 
							ON t.id_formato= f.id_formato
INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
END'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
declare @idioma as tinyint
select @idioma = valor from ccSettings where setting_id=23
if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()
if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSection 
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date < @to
INSERT INTO dbo.RepAVRSSection
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_formato,
	t.nombre,
	c.id_concepto,
	c.con_descripcion,
	r.peso AS scores, 
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	f.id_grabacion,
	(case f.tipo 
		when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' WHEN @idioma = 2 THEN ''Gravações'' ELSE ''Recordings'' END 
		when ''2'' then ''Chat''
	end) as Medio,	
	f.cam_id as CamId,
	f.tipo_llamada as TipoLlamada,	
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,
		f.id_forma,		 
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
END'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
declare @idioma as tinyint
select @idioma = valor from ccSettings where setting_id=23
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()
if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRRateDetail 
	DELETE FROM dbo.RepAVRSRateDetail with(rowlock)
	where date >= @from AND date < @to
	INSERT INTO dbo.RepAVRSRateDetail
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		s.User_id,
		s.Login,
		(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
		f.id_grabacion,
		(case f.tipo 
			when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' WHEN @idioma = 2 THEN ''Gravações'' ELSE ''Recordings'' END 
			when ''2'' then ''Chat''
		end) as Medio,
		t.id_formato,
		t.nombre,
		c.con_descripcion,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso as avgDisposition,	
		r.peso as avgDisposition,	
		r.peso as avgDisposition,
		f.cam_id as CamId,
		f.tipo,
		(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
			AS Cam,
		r.id_forma,
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
	from RIA_RESULTADOSFORMA r
	INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
	INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=1
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
	left join cccamps AS e ON f.cam_id = e.cam_id
	left join ccinbound AS u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
END'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]		
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
declare @idioma as tinyint
select @idioma = valor from ccSettings where setting_id=23
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()
if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent with(rowlock)
	where date >= @from AND date < @to
	INSERT INTO dbo.RepAVRSAgent
	--By Agent		
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		f.total_forma AS scores, 
		f.total_forma AS scores, 
		f.total_forma AS scores,
		s.User_id,
		s.Login,
		(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
		f.id_formato,
		k.nombre,		
		f.id_grabacion,
		(case f.tipo 
			when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' WHEN @idioma = 2 THEN ''Gravações'' ELSE ''Recordings'' END 
			when ''2'' then ''Chat''
		end) as Medio,	
		f.cam_id as CamId,
		f.tipo_llamada as TipoLlamada,	
		(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
			AS Cam,		 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF f
	INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
	INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS 
								WHERE activo = 1 and tipo=1
								GROUP BY id_formato,nombre) as t 
								ON t.id_formato= f.id_formato
	INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
	left join cccamps AS e ON f.cam_id = e.cam_id
	left join ccinbound AS u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
END'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués'
    	set @Sql= 'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestion]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on
declare @idioma as tinyint
select @idioma = valor from ccSettings where setting_id=23
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()
if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSQuestion with(rowlock)
	where date >= @from AND date < @to
	INSERT INTO dbo.RepAVRSQuestion
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		s.User_id,
		s.Login,
		(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
		t.id_formato,
		t.nombre,
		c.id_concepto,
		c.con_descripcion,
		p.id_pregunta,
		p.enunciado_pregunta,
		r.peso as avgDisposition,
		r.peso as avgDisposition,
		r.peso as avgDisposition,
		f.id_grabacion,
		(case f.tipo 
			when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' WHEN @idioma = 2 THEN ''Gravações'' ELSE ''Recordings'' END 
			when ''2'' then ''Chat''
		end) as Medio,	
		f.cam_id as CamId,
		(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
			AS Cam	
	from RIA_RESULTADOSFORMA r
	INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
	INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=1
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
	left join cccamps AS e ON f.cam_id = e.cam_id
	left join ccinbound AS u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
set nocount off
END'
		EXEC(@Sql)

		set @process = 'CW-943 Etiquetas en Portugués'
    	set @Sql= 'ALTER procedure [dbo].[ccsp_getVersion]
@Module varchar(3) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma bit
select @Idioma = cast(valor as bit) from ccSettings where setting_id = 23
if upper(isnull(@Module, '''')) not in (''BD'', ''REP'', ''ALL'')
 begin
	select ''-2'' ID, case @Idioma when 1 then ''ERROR. Invalid module''
	when 2 then ''ERRO. Módulo inválido''
	else ''ERROR. Invalid Module'' end [Description]
	return(0)
 end
if @Module = ''ALL''
 begin
	select valor Ver_BD_REP from ccSettings where setting_id = 24
	return(0)
 end
declare @nVersion varchar(30)
select @nVersion = cast(valor as varchar(15)) from ccSettings where setting_id = 24
BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9)
	set @version_1 = substring(@nVersion, 1, charindex(''.'', @nVersion)-1)
	set @nVersion = substring(@nVersion, charindex(''.'', @nVersion) + 1, len(@nVersion))
	set @version_2 = @nVersion
END TRY
BEGIN CATCH
	select ''-1'' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH
if isnull(@Version, 0) = 0
 begin
	select @version = cast(case upper(@Module) when ''BD'' then @version_1
	else @version_2 end as int)
	select @version Version
	return(@version)
 end
if upper(@Module) = ''BD'' and (@Version <= cast(@version_1 as int) or (@Version - cast(@version_1 as int))>1)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Invalid version for DB current version: '' + @version_1 
	when 2 then ''ERRO. Versão inválida para BD, versão atual: '' + @version_1 
	else ''ERROR. Versión no válida para BD, versión actual: '' + @version_1
	end [Description]
	return(0)
 end
if @Version <= cast(case upper(@Module) when ''BD'' then @version_1
else @version_2 end as int)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Invalid version for '' + @Module + ''. Current version: '' +
	 case upper(@Module) when ''BD'' then @version_1 else @version_2 end
	 when 2 then ''ERRO. Versão inválida para '' + @Module + ''. Versão atual: '' +
	 case upper(@Module) when ''BD'' then @version_1 else @version_2 end
	else ''ERROR. Versión no válida para '' + @Module + ''. Versión actual: '' +
	 case upper(@Module) when ''BD'' then @version_1 else @version_2 end
	end [Description]
	return(0)
 end
if upper(@Module) = ''BD'' set @version_1 = @Version
else set @version_2 = @Version
set @nVersion = @version_1 + ''.'' + @version_2 
update ccSettings set valor = @nVersion where setting_id = 24
if @@rowcount = 1
	select ''0'' ID, ''Actualizado a version: '' + @nVersion [Description]
else
	select ''-4'' ID, case @Idioma when 1 
	then ''ERROR occurred while upgrading to version:'' + @nVersion
	when 2 then ''ERRO encontrado ao atualizar a versão '' + @nVersion
	else ''ERROR generado al actualizar a versión '' + @nVersion
	end [Description]
return (0)
set nocount off'
		EXEC(@Sql)

		 if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off