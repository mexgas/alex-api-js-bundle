CREATE PROCEDURE [dbo].[ccspRepAVRSScores]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
	select @to = getdate()	

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSScores with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSScores
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+' '+u.apellidomaterno+' '+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f 
	INNER JOIN dbo.ccUserView u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
	UNION ALL
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+' '+u.apellidomaterno+' '+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUserView u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
END