/*
Autor: Raymundo Gonzalez
Fecha: 2013/10/31
Descripcion:
	Se crea la tabla ccMenuUser para menus de reportes por usuario
	Se agrega constraint a la tabla ccMenuUser
	Se agregan las columnas provedorId, provider y trunk a la tabla RepInCallsDetail para reporte de Milla
	Se agrega la columna trunk a la tabla RepOutCallsDetail para reporte de Milla
	Se actualizan los registros de la tabla ccmenus para menus de reportes por usuario
	Se elimina llave primaria de ccmenus
	Se agrega llave primaria de ccmenus
	Se actualizan los registros de la tabla ccmenus para reorganizar menus de reportes por usuario
	Se modifica el SP ccspRepOutCallsDetail para reporte de Milla
	Se modifica el SP ccspRepInCallsDetail para reporte de Milla
	Se modifica el SP GetReportMenus para menus de reportes por usuario
	Se modifica el SP SaveReportTemplates para obtener nombre de reporte con nuevo menu
	Se modifica el SP ccspRepAVRSAgent para generacion de reporte por rango de fechas
	Se modifica el SP ccspRepAVRSDisposition para generacion de reporte por rango de fechas
	Se modifica el SP ccspRepAVRSQuestionDetail para generacion de reporte por rango de fechas
	Se modifica el SP ccspRepAVRSRateDetail para generacion de reporte por rango de fechas
	Se modifica el SP ccspRepAVRSScores para generacion de reporte por rango de fechas
	Se modifica el SP ccspRepAVRSSection para generacion de reporte por rango de fechas
	Se modifica el SP ccspRepAVRSSupervisor para generacion de reporte por rango de fechas
	Se reconstruyen los reportes de AVRS
	Se actualiza la informacion de los nuevos campos agregados a la tabla RepInCallsDetail para reporte de Milla
	Se actualiza la informacion de los nuevos campos agregados a la tabla RepOutCallsDetail para reporte de Milla
	Se crea el Job ShrinkLogCCReportsRia para performance
	
Version requerida: 6
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '7'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccMenuUser - Create table'
		set @Sql = 'CREATE TABLE [dbo].[ccMenuUser](
	[id_User] [int] NOT NULL,
	[id_Menu] [int] NOT NULL,
	[type] [tinyint] NOT NULL
) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccMenuUser - Add Constraint'
		set @Sql = 'ALTER TABLE [dbo].[ccMenuUser] ADD  CONSTRAINT [DF_ccMenuUser_type]  DEFAULT ((1)) FOR [type]'
		
	EXEC(@Sql)

		set @process = 'RepInCallsDetail - Alter Table'
		set @Sql = 'alter table RepInCallsDetail add [provedorId] [smallint]
alter table RepInCallsDetail add [provider] [varchar](30)
alter table RepInCallsDetail add [trunk] [smallint]'
		
	EXEC(@Sql)

		set @process = 'RepOutCallsDetail - Alter Table'
		set @Sql = 'alter table RepOutCallsDetail add [trunk] [smallint]'
		
	EXEC(@Sql)
	
		set @process = 'ccmenus - Update'
		set @Sql = 'update ccmenus set type=3'
		
	EXEC(@Sql)
	
		set @process = 'ccmenus - Drop Constraint'
		set @Sql = 'ALTER TABLE ccmenus DROP CONSTRAINT PK_ccMenus'
		
	EXEC(@Sql)
	
		set @process = 'ccmenus - Add Constraint'
		set @Sql = 'ALTER TABLE ccmenus ADD CONSTRAINT PK_ccMenus PRIMARY KEY (menu_id,[type])'
		
	EXEC(@Sql)
	
		set @process = 'ccMenus - Update 2'
		set @Sql = 'update ccMenus set parent=3130 where menu_id in (3131,3132,3133,3134,3135,3136) and type=3
update ccMenus set parent=8050 where menu_id = 8050 and type=3
update ccMenus set parent=8050 where menu_id = 8060 and type=3
update ccMenus set parent=8060 where menu_id in (8061,8062,8063) and type=3
update ccMenus set parent=8050 where menu_id = 8070 and type=3
update ccMenus set parent=8070 where menu_id in (8071,8072) and type=3
update ccMenus set parent=8050 where menu_id = 8080 and type=3'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsDetail where date >= @from AND date < @to

		INSERT INTO RepOutCallsDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else ''systemTranslated_NoCarrier'' end as [ByCarrier],		
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''systemTranslated_Client'' else ''systemTranslated_Agent'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		,Call.cal_puerto
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = 1)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual in (0, 2) 
		order by date
	end'
		
	EXEC(@Sql)

		set @process = 'ccspRepInCallsDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInCallsDetail where date >= @from AND date < @to
	--select * from RepInCallsDetail
	--select top 10 * from cccallsin

	insert into RepInCallsDetail
	select cal_inicio, Inbound_id, '''', statusCall_id, '''', calif_id, '''', isnull(califSub_id,0), '''', dni_id, '''', user_id, '''',
	isnull(cal_key,''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''',
	cal_whoHung, cal_tMoh, datepart(yyyy,cal_inicio), datepart(mm,cal_inicio), datepart(dd,cal_inicio)
	, datepart(hh,cal_inicio), datepart(mi,cal_inicio)
	,di.provedor_id,prov.descrip [Proveedor],a.cal_puerto
	from cccallsin a
	left join ccoDialers di on di.dialer_id = a.cal_puerto
	left join cstoProvedor prov on di.provedor_id = prov.provedor_id
	where cal_inicio >= @from AND cal_inicio < @to

	update a set acdGroup = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,'''')
	from RepInCallsDetail a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,'''')
	from RepInCallsDetail a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInCallsDetail a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set dnis = isnull(dni_numero,'''')
	from RepInCallsDetail a
	left join ccdnis b 
	on a.dnisId = b.dni_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInCallsDetail a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@sql)

		set @process = 'GetReportMenus - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint
AS
BEGIN


	Select distinct
		b.Nivel as Nivel,
		substring(b.menu_descrip, charindex(''|'', b.menu_descrip) + 1, len(b.menu_descrip)) as menu_descrip,
		b.menu_id as menu_id,
		b.ordengral as ordengral,
		5 as filtersType		
	from
		ccMenus as b with(nolock)
		inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId
	where
		b.type = 3
		and (menu_id >= 2000) 
		and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
		or  (menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1 )
		or  (menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
			
union
	select distinct b.Nivel as Nivel,
			substring(b.menu_descrip, charindex(''|'', b.menu_descrip) + 1, len(b.menu_descrip)) as menu_descrip,
			b.menu_id as menu_id,
			b.ordengral as ordengral,
			5 as filtersType from (
	Select distinct	b.Parent
		from ccMenus as b with(nolock)
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId
			where b.type = 3 and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
		or  (menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1 )
		or  (menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
	)x inner join ccMenus b on x.Parent = b.menu_id
union
	select distinct b.Nivel as Nivel,
			substring(b.menu_descrip, charindex(''|'', b.menu_descrip) + 1, len(b.menu_descrip)) as menu_descrip,
			b.menu_id as menu_id, b.ordengral as ordengral,	5 as filtersType from(
	select b.Parent from (Select distinct	b.Parent
		from ccMenus as b with(nolock)
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId
			where b.type = 3 and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
		or  (menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1 )
		or  (menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
	)x inner join ccMenus b on x.Parent = b.menu_id
	)y inner join ccMenus b on y.Parent = b.menu_id
order by menu_id
END'
		
	EXEC(@Sql)

		set @process = 'SaveReportTemplates - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[SaveReportTemplates] @userId int, @process int, @parameters varchar(max)
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

	select @reportName = substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip))
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

		set @process = 'ccspRepAVRSAgent -Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgent
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
	
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSDisposition - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSDisposition]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSDisposition where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDisposition 
	SELECT f.fecha_calif,t.id_formato,t.nombre,u.User_id,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agente,f.id_grabacion,f.total_forma,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u 
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,t.nombre,u.login
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSQuestionDetail -Alter procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSQuestionDetail where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSQuestionDetail
	SELECT f.fecha_calif, f.id_grabacion, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], (s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS [supervisor], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion,
		   p.id_pregunta, p.enunciado_pregunta, r.etiquetas, r.peso AS [score], b.finicio, 
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    	FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
					  FROM RIA_FORMATOS
					  WHERE activo = 1
					  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN ccUsers s
	ON f.id_supervisor =  s.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta) INNER JOIN RIA_GRABACION b
	ON f.id_grabacion = b.grab_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	UNION ALL
	SELECT f.fecha_calif, f.id_grabacion, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], (s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS [supervisor], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion,
		   p.id_pregunta, p.enunciado_pregunta, r.etiquetas, r.peso AS [score], b.finicio, 
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    	FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
					  FROM RIA_FORMATOS
					  WHERE activo = 1
					  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN ccUsers s
	ON f.id_supervisor =  s.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta) INNER JOIN RIA_GRABACIONCONSULTA b
	ON f.id_grabacion = b.grab_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,c.id_concepto,c.con_descripcion,t.id_formato,t.nombre,u.Login,u.User_id,agent
	
set nocount off
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSRateDetail -Alter procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRRateDetail 
	DELETE FROM dbo.RepAVRSRateDetail where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSRateDetail
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS supervisor,
		   g.grab_id,t.id_formato,t.nombre AS formato,f.total_forma,g.finicio,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN dbo.RIA_GRABACION g
		 ON f.id_grabacion = g.grab_id INNER JOIN dbo.ccUsers s
		 ON f.id_supervisor = s.User_Id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	UNION ALL
	SELECT f.fecha_calif,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS supervisor,
		   g.grab_id,t.id_formato,t.nombre AS formato,f.total_forma,g.finicio,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN dbo.RIA_GRABACIONCONSULTA g
		 ON f.id_grabacion = g.grab_id INNER JOIN dbo.ccUsers s
		 ON f.id_supervisor = s.User_Id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,u.login,t.nombre
END'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepAVRSScores - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSScores]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()	

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSScores where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSScores
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
	UNION ALL
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSSection - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSSection 
	DELETE FROM dbo.RepAVRSSection  where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSSection
	SELECT f.fecha_calif, u.user_id, u.login, (u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS [agent], t.id_formato, t.nombre, c.id_concepto, c.con_descripcion, SUM(r.peso) AS [score],
		   YEAR(f.fecha_calif) AS [year], MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
    	FROM RIA_FORMACALIF f INNER JOIN (SELECT id_formato, nombre, MAX(version) AS [version]
					  FROM RIA_FORMATOS
					  WHERE activo = 1
					  GROUP BY id_formato, nombre) AS t
	ON (f.id_formato = t.id_formato) AND (f.version = t.version) INNER JOIN ccUsers u
	ON f.age_id = u.user_id INNER JOIN RIA_CONCEPTOS c
	ON (t.id_formato = c.id_formato) AND (t.version = c.version) INNER JOIN RIA_PREGUNTAS p
	ON c.id_concepto = p.id_concepto INNER JOIN RIA_RESULTADOSFORMA r
	ON (f.id_forma = r.id_forma) AND (r.id_pregunta = p.id_pregunta)
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY f.fecha_calif,c.id_concepto,c.con_descripcion,t.id_formato,t.nombre,u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres
END'
		
	EXEC(@Sql)

		set @process = 'ccspRepAVRSSupervisor - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()	

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSSupervisor 
	DELETE FROM dbo.RepAVRSSupervisor  where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSSupervisor
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUsers u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
END'
		
	EXEC(@Sql)

		set @process = 'AVRS - Rebuild Reports'
		set @Sql = 'IF EXISTS (select * from sysobjects where name = ''RIA_FORMACALIF'')
BEGIN
	declare @from as datetime
			
	select @from = MIN(date) FROM RepAVRSAgent
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSAgent] 1,@from

	select @from = MIN(date) FROM RepAVRSDisposition
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSDisposition] 1,@from

	select @from = MIN(date) FROM RepAVRSQuestionDetail
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSQuestionDetail] 1,@from

	select @from = MIN(date) FROM RepAVRSRateDetail
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSRateDetail] 1,@from

	select @from = MIN(date) FROM RepAVRSScores
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSScores] 1,@from

	select @from = MIN(date) FROM RepAVRSSection
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSSection] 1,@from

	select @from = MIN(date) FROM RepAVRSSupervisor
	set @from = convert(datetime,convert(varchar(11),@from))
	EXEC [ccspRepAVRSSupervisor] 1,@from
END'
		
	EXEC(@Sql)

		set @process = 'RepInCallsDetail - Update'
		set @Sql = 'update rep 
set rep.provedorId = di.provedor_id, rep.provider = prov.descrip,rep.trunk = a.cal_puerto
from RepInCallsDetail rep 
inner join cccallsin a on rep.date = a.cal_inicio and a.Inbound_id = rep.inboundId and a.[User_id] = rep.userId and a.dni_id = rep.dnisId
left join ccoDialers di on di.dialer_id = a.cal_puerto
left join cstoProvedor prov on di.provedor_id = prov.provedor_id'
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallsDetail - Update'
		set @Sql = 'update rep  
set rep.trunk = a.cal_puerto
from RepOutCallsDetail rep 
inner join ccoCallsOut a on rep.date = a.cal_inicio and a.cam_id = rep.campaignId and a.[User_id] = rep.userId'
		
	EXEC(@Sql)

		set @process = 'ShrinkLogCCReportsRia - Create Job'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ShrinkLogCCReportsRia]    Script Date: 10/23/2013 11:02:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 10/23/2013 11:02:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ShrinkLogCCReportsRia'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Shrink Log CCReportsRia'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 10/23/2013 11:02:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Checkpoint DB]    Script Date: 10/23/2013 11:02:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Checkpoint DB'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''CHECKPOINT'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 10/23/2013 11:02:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccReports_Log'''',1)'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Weekly'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20000101, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
	EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
