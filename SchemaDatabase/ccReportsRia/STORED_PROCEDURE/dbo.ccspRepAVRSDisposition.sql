CREATE PROCEDURE [dbo].[ccspRepAVRSDisposition]
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
	DELETE FROM dbo.RepAVRSDisposition with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDisposition 
	SELECT f.fecha_calif,t.id_formato,t.nombre,u.User_id,(u.apellidopaterno+' '+u.apellidomaterno+' '+u.nombres) AS agente,f.id_grabacion,f.total_forma,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUserView u 
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,t.nombre,u.login
END