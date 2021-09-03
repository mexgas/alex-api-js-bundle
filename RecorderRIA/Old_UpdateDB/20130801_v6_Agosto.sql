/*

Fecha: 2013/08/01
Descripcion: 	

Version requerida: 5
*/

set nocount on
declare @Version int
declare @Version_Actual int
declare @procedure varchar(max)
---------------- VERSION ----------------
Set @Version = 6
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------

-- ALTERANDO LAS VISTAS

-- Vista trvw_tl_ccCamps

set @process = 'trvw_tl_ccCamps - Alter View'
set @Sql= ' ALTER VIEW [dbo].[trvw_tl_ccCamps] AS
SELECT     cam_id, cam_descripcion
FROM       ccCamps
'

EXEC(@Sql)

-- Vista trvw_tl_ccInbound

set @process= 'trvw_tl_ccInbound - Alter view'
set @Sql='
ALTER VIEW [dbo].[trvw_tl_ccInbound]
AS
SELECT     Inbound_id, descripcion
FROM       ccInbound
GO
'

EXEC(@Sql)


-- Vista trvw_tl_ccTipoCalif

set @process= 'trvw_tl_ccTipoCalif - Alter view'
set @Sql='
ALTER VIEW [dbo].[trvw_tl_ccTipoCalif]
AS
SELECT     calif_id, Description
FROM       ccTipoCalif
'

EXEC(@Sql)


-- Vista trvw_tl_ccUsers

set @process= 'trvw_tl_ccUsers - Alter view'
set @Sql='
ALTER VIEW [dbo].[trvw_tl_ccUsers]
AS
SELECT     User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoUser_id
FROM       ccUsers
'

EXEC(@Sql)


-- Vista trvw_tl_RIA_GRABACION

set @process= 'trvw_tl_RIA_GRABACION - Alter view'
set @Sql='
ALTER VIEW [dbo].[trvw_tl_RIA_GRABACION]
AS
SELECT     grab_id, age_id, finicio, duracion, id_repositorio, tipo_llamada, cam_id, calif_id, cal_id, ffin, ani, dni, id_nivel_grito, cal_key, cal_manual, cal_extension
FROM       RIA_GRABACION
UNION
SELECT     grab_id, age_id, finicio, duracion, id_repositorio, tipo_llamada, cam_id, calif_id, cal_id, ffin, ani, dni, id_nivel_grito, cal_key, cal_manual, cal_extension
FROM       RIA_GRABACIONCONSULTA

'

EXEC(@Sql)



-- Se agregan store procedures que no encuentra el CCRecorder

-- STORE PROCEDURE trsp_GetSysLogParams

set @process= 'trsp_GetSysLogParams - Create procedure'
set @Sql = '
CREATE PROCEDURE [dbo].[trsp_GetSysLogParams]
AS
BEGIN
    select id, par_valor from TREC_SYSLOG_PARAMS
END

'
EXEC(@Sql)

---------------------------------------------------------------
-- STORE PROCEDURE trsp_GetListaBorrarRespaldo

set @process = 'trsp_GetListaBorrarRespaldo - Create procedure'
set @Sql = '
CREATE PROCEDURE [dbo].[trsp_GetListaBorrarRespaldo]
@cwIntegrated AS INT
AS
BEGIN
    IF @cwIntegrated = 1
	BEGIN
	    select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio from TREC_BACKUPS inner join 
		(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
		ON TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 order by grab_id asc;

	END
	ELSE
	BEGIN
	    select top 10000 grab_id, status_audio from trec_backups where status_audio = 1 order by grab_id asc
	END
END

'
EXEC(@Sql)


---------------------------------------------------------------
-- STORE PROCEDURE trsp_GetListaBorrarSinRespaldo

set @process = 'trsp_GetListaBorrarSinRespaldo - Create procedure'
set @Sql = '
CREATE PROCEDURE [dbo].[trsp_GetListaBorrarSinRespaldo]
@cwIntegrated AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @maxBorrado INT
	DECLARE @datosTabla INT
	DECLARE @maxGrabId INT

    -- Insert statements for procedure here
	SELECT @maxBorrado = MAX(grab_id) from trec_backups where status_audio = 4 or status_audio = 5;
	SELECT @datosTabla = COUNT(grab_id) from trec_backups where grab_id > @maxBorrado;
	SELECT @maxGrabId = MAX(grab_id) from trec_backups;
	IF @datosTabla < 10000
	   BEGIN
	       insert into TREC_BACKUPS (grab_id,status_audio)
	       select grab_id,2 as status_audio from TREC_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);		
	   END
	IF @cwIntegrated = 1
	    BEGIN
		select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
		(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
		on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
	ELSE
	    BEGIN
		select top 10000 grab_id, status_audio, status_video from trec_backups where status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
END

'
EXEC(@Sql)

---------------------------------------------------------------
-- STORE PROCEDURE trsp_UpdateArchivoGrabacion

set @process = 'trsp_UpdateArchivoGrabacion - Create procedure'
set @Sql = '
CREATE PROCEDURE [dbo].[trsp_UpdateArchivoGrabacion]
@activeid int
AS
BEGIN
    DECLARE @maxid INT
	SELECT @maxid=max(grab_id_max)  from TREC_Archivo_GRABACION where hecho = ''true'';
    IF @activeid > @maxid
    BEGIN
        SELECT @activeid = @maxid;
    END
    UPDATE TREC_Archivo_GRABACION set grab_id_active = @activeid where grab_id_max = @maxid;
END

'
EXEC(@Sql)


-----------------------------------------------------------------
-- STORE PROCEDURE trsp_UpdateStatusBackup

set @process = 'trsp_UpdateStatusBackup - Create procedure'
set @Sql = '
CREATE PROCEDURE [dbo].[trsp_UpdateStatusBackup]
@status as int,
@statusVideo as int,
@grabId as int
AS
BEGIN
	UPDATE TREC_BACKUPS set status_audio = @status, status_video = @statusVideo where grab_id = @grabId;
END

'
EXEC(@Sql)


-------------------------------------------------------------------
-- ALTER PROCEDURES TO REMOVE LINK SERVER

-- STORE PROCEDURE trsp_AdmGetSupervisorsForAgent

set @process = 'trsp_AdmGetSupervisorsForAgent - Alter procedure'
set @Sql = '
ALTER PROCEDURE [dbo].[trsp_AdmGetSupervisorsForAgent]

@cal_id int,
@tipo_llamada int

AS
BEGIN

	SET NOCOUNT ON;

declare @age_id int

set @age_id = (select age_id from (select age_id from RIA_GRABACION where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from RIA_GRABACIONCONSULTA where cal_id = @cal_id and tipo_llamada = @tipo_llamada)x)


select distinct a1.user_id as agt, a5.user_id as sup, a5.login from ccusers a1 
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join 
(select a3.user_id, a4.IDWG, a3.login  from ccusers a3 
inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)
where a1.user_id = @age_id
order by a1.user_id,a5.user_id

END
'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmGetSupervisorsName

set @process = 'trsp_AdmGetSupervisorsName - Alter procedure'
set @Sql='
ALTER PROCEDURE  [dbo].[trsp_AdmGetSupervisorsName]

@user_id int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select IsNULL(Nombres,'''') as nombre ,ISNULL(ApellidoPaterno,'''') as apellidopaterno, ISNULL(ApellidoMaterno,'''') as apellidomaterno from ccUsers where user_id = @user_id


END
'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmGetMarks

set @process = 'trsp_AdmGetMarks - Alter procedure'
set @Sql = '

ALTER PROCEDURE [dbo].[trsp_AdmGetMarks]

@cal_id int,
@tipo_llamada int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


declare @grab_id int,
@login nvarchar(MAX)


set @grab_id = (select grab_id from (select grab_id from RIA_GRABACION where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from RIA_GRABACIONCONSULTA where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


select a.id_marca,a.user_id,b.login, a.marca, a.tipo_marca  from RIA_MARCAS a inner join ccUsers b on a.grab_id = @grab_id  and b.user_id = a.user_id order by marca


END
'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmPCIGetCamp

set @process = 'trsp_AdmPCIGetCamp - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmPCIGetCamp]

@User_id int 

AS
BEGIN

	 
	 select a1.cam_id, a1.cam_Descripcion , a3.frame, isnull(a4.Xtime,0) as Xtime,  isnull(a4.ActiveXtime,0) as ActiveXtime, isnull(a4.onOff,0) as OnOff
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
     left join RIA_PCI_CAMP_SETTINGS a4 on (a4.cam_id = a1.cam_id) 
	 --where a1.cam_id in (select cam_id from CCenterRIA.dbo.fGet_CampAcd_Area (@User_id, 1))
     where a1.cam_id in (select cam_id from fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion

END
'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmPCIGetACD

set @process = 'trsp_AdmPCIGetACD - Alter procedure'
set @Sql= '
ALTER PROCEDURE [dbo].[trsp_AdmPCIGetACD]

@User_id int 

AS
BEGIN

	SET NOCOUNT ON;

	 select a1.Inbound_id, a1.descripcion , a3.frame, isnull(a4.Xtime,0) as Xtime, isnull(a4.ActiveXtime,0) as ActiveXtime, isnull(a4.onOff,0) as OnOff

	 from ccInbound a1 inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
     left join RIA_PCI_ACD_SETTINGS a4 on (a4.Inbound_id = a1.Inbound_id)
	 where a1.Inbound_id in (select cam_id from fGet_CampAcd_Area (@User_id, 2))
	 order by descripcion

END

'
EXEC(@Sql)

-- STORE PROCEDURE trsp_AdmPCIGetDefaultList

set @process = 'trsp_AdmPCIGetDefaultList - Alter procedure'
set @Sql= '
ALTER PROCEDURE [dbo].[trsp_AdmPCIGetDefaultList]

@ListType int


AS
BEGIN

declare @Idiom int

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;

set @Idiom = (select valor from ccSettings where setting_id = 27)

if @Idiom = 0

Begin

select PalabraClave from RIA_PCI_DEFAULT_LIST where List_Type = @ListType

End

Else IF @idiom = 1

Begin

select Keyword from RIA_PCI_DEFAULT_LIST where List_Type = @ListType

End

END

'
EXEC(@Sql)

-- STORE PROCEDURE trspAdmRecordingInfo

set @process = 'trspAdmRecordingInfo - Alter procedure'
set @Sql='
ALTER PROCEDURE  [dbo].[trspAdmRecordingInfo]
@grab_id as INT
AS
set nocount on

BEGIN
select a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno,b.cal_id,
CASE WHEN b.tipo_llamada=1 THEN ''Inbound''ELSE ''Outbound'' END,
CASE WHEN b.tipo_llamada=1 THEN c.descripcion  ELSE d.cam_descripcion END,
CASE WHEN b.tipo_llamada=1 THEN e.description ELSE f.description END,
CASE WHEN b.tipo_llamada=1 THEN g.cal_ANI ELSE h.cal_telefono END,
(select top 1 IP from ccPosicion where user_id = a.User_id order by pos_id desc),
CASE WHEN b.cal_extension IS NULL THEN 0 ELSE b.cal_extension END,
DATEADD(dd, 0, DATEDIFF(dd, 0, b.finicio)) as fecha,
RIGHT(CONVERT(DATETIME, b.finicio, 108),8),
CASE WHEN b.duracion/3600<10 THEN ''0'' ELSE '''' END + RTRIM(b.duracion/3600) + '':'' + RIGHT(''0''+RTRIM((b.duracion % 3600) / 60),2) + '':'' + RIGHT(''0''+RTRIM((b.duracion % 3600) % 60),2)
FROM 
ccUsers a LEFT JOIN dbo.RIA_GRABACION b ON a.User_id=b.age_id 
LEFT JOIN  ccInbound c ON b.cam_id=c.Inbound_id
LEFT JOIN  ccCamps d ON b.cam_id=d.cam_id
LEFT JOIN  ccTipoCalif e ON b.calif_id=e.calif_id
LEFT JOIN  ccTipoCalifOUT f ON b.calif_id=f.calif_id 
LEFT JOIN  ccCallsIn g ON b.cal_id=g.cal_id
LEFT JOIN  ccoCallsOut h ON b.cal_id=h.cal_id
WHERE b.grab_id=@grab_id
END

'
EXEC(@Sql)


-- STORE PROCEDURE trspAdmRecordingsOfDay

set @process = 'trspAdmRecordingsOfDay - Alter procedure'
set @Sql='
ALTER PROCEDURE  [dbo].[trspAdmRecordingsOfDay]
@idAgent as INT
AS
set nocount on
DECLARE @CallType as INT

BEGIN
	(SELECT     a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN g.cal_telefono ELSE h.cal_ANI END AS Expr1, 
                      b.cam_descripcion AS Expr2, 
                      CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE WHEN a.tipo_llamada = 2 THEN d .description ELSE e.description END AS Expr4, 
                     isnull(a.id_nivel_grito,-1),@idAgent as age_id, isnull (i.total_forma,0) as rating,j.Computer, k.Nombres AS Agente
	FROM         RIA_GRABACION AS a INNER JOIN
                      ccCamps AS b ON a.cam_id = b.cam_id LEFT OUTER JOIN
                      ccTipoCalifOUT AS d ON a.calif_id = d.calif_id LEFT OUTER JOIN
                      ccTipoCalif AS e ON a.calif_id = e.calif_id LEFT OUTER JOIN
                      RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito LEFT OUTER JOIN
                      ccoCallsOut AS g ON a.cal_id = g.cal_id LEFT OUTER JOIN
                      ccCallsIn AS h ON a.cal_id = h.cal_id LEFT OUTER JOIN
					  RIA_FORMACALIF AS i on i.id_grabacion = a.grab_id left join 
					  ccPosicion j on j.pos_id = a.cal_extension * -1 left join 
					  ccUsers k on k.User_id = @idAgent
WHERE     (a.age_id = @idAgent) AND (a.tipo_llamada=2) AND(DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))

UNION ALL

	(SELECT     a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN g.cal_telefono ELSE h.cal_ANI END AS Expr1, 
                      c.descripcion AS Expr2, 
                      CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE WHEN a.tipo_llamada = 2 THEN d .description ELSE e.description END AS Expr4, 
                      isnull(a.id_nivel_grito,-1),@idAgent as age_id, isnull (i.total_forma,0) as rating, j.Computer, k.Nombres AS Agente
	FROM         RIA_GRABACION AS a INNER JOIN
                      ccInbound AS c ON a.cam_id = c.Inbound_id LEFT OUTER JOIN
                      ccTipoCalifOUT AS d ON a.calif_id = d.calif_id LEFT OUTER JOIN
                      ccTipoCalif AS e ON a.calif_id = e.calif_id LEFT OUTER JOIN
                      RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito LEFT OUTER JOIN
                      ccoCallsOut AS g ON a.cal_id = g.cal_id LEFT OUTER JOIN
                      ccCallsIn AS h ON a.cal_id = h.cal_id LEFT OUTER JOIN
					  RIA_FORMACALIF AS i on i.id_grabacion = a.grab_id left join 
					  ccPosicion j on j.pos_id = a.cal_extension * -1 left join 
					  ccUsers k on k.User_id = @idAgent
WHERE     (a.age_id = @idAgent) AND (a.tipo_llamada=1) AND (DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))
END

'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmRecGetWGforSearch

set @process = 'trsp_AdmRecGetWGforSearch - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecGetWGforSearch]

@Cal_id int,
@User_id int,
@CallType int



AS
BEGIN

	SET NOCOUNT ON;

select IDWG from ccRIAWorkGroup_Calid where cal_id = @Cal_id and User_id = @User_id and tipo = @CallType

END

'
EXEC(@Sql)

-- STORE PROCEDURE trsp_AdmRecSearchOneDay

set @process = 'trsp_AdmRecSearchOneDay - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
	-- Add the parameters for the stored procedure here
@Sup_id int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, a.cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer, 
isnull (d.total_forma,0) as total_forma, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion

from RIA_GRABACION a 
left join ccPosicion b 
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
where 
(a.finicio >= Convert(nvarchar(11),Getdate(),120))
and(
(Tipo_llamada = 2 and
a.cam_id in 
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1))
OR
(Tipo_llamada = 1 and
a.cam_id in
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))

order by finicio desc

END

'
EXEC(@Sql)

-- STORE PROCEDURE trsp_AdmRecSearchCalID

set @process = 'trsp_AdmRecSearchCalID - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
	-- Add the parameters for the stored procedure here
@Sup_id int,
@CalID int

AS
BEGIN

	SET NOCOUNT ON;

select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, a.cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from RIA_GRABACION a 
left join ccPosicion b
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
where 
(a.cal_id = @CalID)
and(
(Tipo_llamada = 2 and
a.cam_id in 
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1))
OR 
(Tipo_llamada = 1 and
a.cam_id in
(select distinct a.IdCampEsp from CCRIACampEspWG a
inner join ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))

order by finicio desc

END

'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmGetMarks

set @process ='trsp_AdmGetMarks - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmGetMarks]

@cal_id int,
@tipo_llamada int


AS
BEGIN

	SET NOCOUNT ON;


declare @grab_id int,
@login nvarchar(MAX)


set @grab_id = (select grab_id from (select grab_id from RIA_GRABACION where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from RIA_GRABACIONCONSULTA where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


select a.id_marca,a.user_id,b.login, a.marca, a.tipo_marca  from RIA_MARCAS a inner join ccUsers b on a.grab_id = @grab_id  and b.user_id = a.user_id order by marca


END

'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmRecSearchAllRecs

set @process = 'trsp_AdmRecSearchAllRecs - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
	-- Add the parameters for the stored procedure here
@Sup_id int,
@Finicio datetime,
@Ffin datetime


AS
BEGIN

	SET NOCOUNT ON;


SELECT * from (

select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, a.cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from RIA_GRABACION a 
left join ccPosicion b 
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
where 
(a.finicio BETWEEN  @Finicio AND @Ffin) 
     and
    (
      (Tipo_llamada = 2 and a.cam_id in 
       (select distinct a.IdCampEsp from CCRIACampEspWG a inner join ccRIAWorkGroupUsers b
          on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
          where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
        )
      )
      OR 
     (Tipo_llamada = 1 and a.cam_id in
      (select distinct a.IdCampEsp from CCRIACampEspWG a inner join ccRIAWorkGroupUsers b
        on b.User_id = @Sup_id inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
        where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
       )
     )
   )

--order by finicio desc

UNION

select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, a.cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from RIA_GRABACIONCONSULTA a 
left join ccPosicion b 
on b.pos_id = a.cal_extension * -1
left join RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
ccTipoCalif AS f ON a.calif_id = f.calif_id
where 
(a.finicio BETWEEN  @Finicio AND @Ffin) 
     and
    (
      (Tipo_llamada = 2 and a.cam_id in 
       (select distinct a.IdCampEsp from CCRIACampEspWG a inner join ccRIAWorkGroupUsers b
          on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
          where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
        )
      )
      OR 
     (Tipo_llamada = 1 and a.cam_id in
      (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
        on b.User_id = @Sup_id inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG
        where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
       )
     )
   )

--order by finicio desc

)  x order by finicio desc


END

'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmX

set @process = 'trsp_AdmX - Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmX]

@Sup_id int,
@Finicio1 datetime,
@Finicio2 datetime

AS
DECLARE    @grab_id INT,@age_id INT,@ffin datetime,@finicio datetime,@duracion INT,@id_repositorio INT,@id_nivel_grito INT,@tipo_llamada INT,@cam_id varchar(80),@calif_id INT,@ani  varchar(80),@dni varchar(80),@cal_id INT,@cal_key varchar(80),@cal_manual INT,@formato_duracion varchar(15) --cursor I
DECLARE @TablaTemporal TABLE(grab_id numeric(18,0),finicio datetime,duracion numeric(18,0),tipo_llamada numeric(18,0),cam_id varchar(80),descipcion varchar(80),user_idd numeric(18,0),loginn varchar(80),Nombres varchar(80),ApellidoPaterno varchar(80), ApellidoMaterno varchar(80),calif_id numeric(18,0),descripcionC varchar(80),cal_id numeric(18,0),id_repositorio numeric(18,0),ffin datetime,id_nivel_grito numeric(18,0),ani varchar(80),dni varchar(80),cal_key varchar(80),cal_manual numeric(18,0),Computer varchar(80),pos_id numeric(18,0),total_forma numeric(18,0),score varchar(80),formato_duracion varchar(15))
BEGIN
	 SET NOCOUNT ON;
   DECLARE @vt1 varchar(80)
   DECLARE @vt2 varchar(80)
   DECLARE @vt3 varchar(80)
   DECLARE @vt4 varchar(80)
   DECLARE @vt5 varchar(80)
   DECLARE @vt6 varchar(80)
   DECLARE @vt7 varchar(80)
   DECLARE @vt8 varchar(80)
   DECLARE @vt9 int
   DECLARE @vt10 int
   DECLARE @vt22 varchar(80)
   DECLARE @tipoUs int
	
   SET @grab_id=0
   SET @age_id=0
   SET @ffin='' ''
   SET @finicio='' ''
   SET @duracion='' ''
   SET @id_repositorio='' ''
   SET @tipo_llamada=0
   SET @cam_id='' ''
   SET @calif_id='' ''
   SET @cal_id='' ''


   DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,cal_manual, 
					 CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
					 FROM dbo.trvw_tl_RIA_GRABACION    
					 where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
   OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
        WHILE (@@FETCH_STATUS = 0 ) BEGIN
            SET @vt2 = (SELECT User_id from dbo.trvw_tl_ccUsers where User_id=@age_id)
            SET @vt3 = (SELECT Login from dbo.trvw_tl_ccUsers where User_id=@age_id)
            SET @vt4 = (SELECT Nombres from dbo.trvw_tl_ccUsers where User_id=@age_id)
            SET @vt5 = (SELECT ApellidoPaterno from dbo.trvw_tl_ccUsers where User_id=@age_id)
            SET @vt6 = (SELECT ApellidoMaterno from dbo.trvw_tl_ccUsers where User_id=@age_id)
            SET @vt7 = (SELECT Description from dbo.trvw_tl_ccTipoCalif where calif_id=@calif_id)
            SET @vt8 = (SELECT b.computer  as pos_id from dbo.trvw_tl_RIA_GRABACION a,dbo.ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
            SET @tipoUs = (SELECT TipoUser_id from dbo.trvw_tl_ccUsers where User_id=@age_id)
            SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from dbo.trvw_tl_RIA_GRABACION a,dbo.ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
			SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
			
			IF(@tipo_llamada=1 and @tipoUs=1) 
              BEGIN           
			   SET @vt1 = (SELECT descripcion from dbo.trvw_tl_ccInbound where Inbound_id=@cam_id)
               SET @vt22 = (SELECT Description from dbo.ccTipoCalif where calif_id=@calif_id)
               INSERT INTO @TablaTemporal(grab_id,finicio,duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,ffin,id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion)values(@grab_id,@finicio,@duracion,@tipo_llamada,@cam_id,@vt1,@vt2,@vt3,@vt4,@vt5,@vt6,@calif_id,@vt7,@cal_id,@id_repositorio,DATEADD(second,@duracion,@finicio),@id_nivel_grito,@ani,@dni,@cal_key,@cal_manual,@vt8,@vt9,@vt10,@vt22,@formato_duracion) 
               END
            ELSE IF(@tipo_llamada=2 and @tipoUs=1)
              BEGIN 
                SET @vt1 = (SELECT cam_descripcion from dbo.trvw_tl_ccCamps where cam_id=@cam_id)
                SET @vt22 = (SELECT Description from ccTipoCalifOUT where calif_id=@calif_id)
			    INSERT INTO @TablaTemporal(grab_id,finicio,duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,ffin,id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion)values(@grab_id,@finicio,@duracion,@tipo_llamada,@cam_id,@vt1,@vt2,@vt3,@vt4,@vt5,@vt6,@calif_id,@vt7,@cal_id,@id_repositorio,DATEADD(second,@duracion,@finicio),@id_nivel_grito,@ani,@dni,@cal_key,@cal_manual,@vt8,@vt9,@vt10,@vt22,@formato_duracion)  
              END
            ELSE
               BEGIN           
               print @grab_id
            END
   
        SET @vt1= '' ''
        SET @vt2= '' ''
        SET @vt3= '' ''
        SET @vt4= '' ''
        SET @vt5= '' ''
        SET @vt6= '' ''
	    SET @vt7= '' ''
	    SET @vt8= '' ''
        SET @vt9= '' ''
        SET @vt10= '' ''
		SET @vt22= '' ''
        SET @tipoUs= '' ''
        FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
        END
CLOSE ElCursorI
DEALLOCATE ElCursorI
	SELECT grab_id,CONVERT(VARCHAR(24),finicio,120) as ''finicio'',duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,CONVERT(VARCHAR(24),ffin,120) as ''ffin'',id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion
	FROM @TablaTemporal
	ORDER BY finicio,duracion
END

'
EXEC(@Sql)

-- STORE PROCEDURE ccspAgent_GetLastCalls

set @process= 'ccspAgent_GetLastCalls- Alter procedure'
set @Sql='
ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls]

@User_id int

AS
BEGIN

	SET NOCOUNT ON;

	
	Select primera.id_formato, convert(nvarchar(20),segunda.finicio,120), tercera.cam_descripcion, convert(nvarchar(20),primera.fecha_calif,120), 
primera.total_forma, segunda.tipo_llamada, primera.id_grabacion, cuarta.login from

RIA_FormaCalif primera 

inner join 

RIA_Grabacion segunda on primera.age_id = @User_id and segunda.grab_id = primera.id_grabacion 

inner join 

ccCamps tercera on segunda.cam_id = tercera.cam_id

inner join

ccUsers cuarta on primera.id_calificador = cuarta.user_id

	
END

'
EXEC(@Sql)


-- STORE PROCEDURE trsp_AdmAVRSReportCallInfo

set @process = 'trsp_AdmAVRSReportCallInfo - Alter procedure'
set @Sql='
ALTER  PROCEDURE [dbo].[trsp_AdmAVRSReportCallInfo]
@id_formato int,
@version int,
@call_id int,
@tipo int
AS
BEGIN
declare @id_grabacion as int
set @id_grabacion=(select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
		  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACION.ani AS Telfono ,Tipo=
																				CASE WHEN (SELECT tipo_llamada 
																						    FROM RIA_GRABACION 
																					        WHERE grab_id=@id_grabacion)=1 THEN ''inbound'' 
																				ELSE ''outbound'' 
																			    END,
						      RIA_GRABACION.finicio AS Fecha,RIA_GRABACION.cal_id AS [Id de llamada],RIA_GRABACION.grab_id AS [Id de Grabacion],
							  RIA_GRABACION.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACION.duracion,''2'') AS Duracion,
							  [Campaña/GrupO ACD]=
							    CASE WHEN (SELECT tipo_llamada 
										   FROM RIA_GRABACION 
										   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																	   FROM RIA_GRABACION INNER JOIN
																	   ccInbound ON RIA_GRABACION.cam_id = ccInbound.Inbound_id
																	   WHERE (RIA_GRABACION.grab_id = @id_grabacion)) 
		     					ELSE (SELECT     ccCamps.cam_descripcion
									  FROM       RIA_GRABACION INNER JOIN
									  ccCamps ON RIA_GRABACION.cam_id = ccCamps.cam_id
									  WHERE     (RIA_GRABACION.grab_id = @id_grabacion))
								END,
							  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
					    FROM  RIA_FORMACALIF INNER JOIN
							 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
							  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
							  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
							  RIA_GRABACION ON RIA_FORMACALIF.id_grabacion = RIA_GRABACION.grab_id INNER JOIN
							  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
						WHERE RIA_FORMACALIF.id_formato=@id_formato and
							  RIA_FORMACALIF.version=@version and
							  RIA_FORMACALIF.id_grabacion=@id_grabacion and
							  RIA_FORMATOS.version=@version
								
END

'
EXEC(@Sql)




-- Inserta nuevo parametro en TREC_PARAMETROS para Export Service

set @process = 'TREC_PARAMETROS - Insert value in par_id 63'
set @Sql ='
INSERT INTO [TREC_PARAMETROS]
           ([par_id]
           ,[par_descripcion]
           ,[par_valor]
           ,[par_detail])
     VALUES
           (63
           ,''Nuxiba Export Service activo''
           ,''0''
           ,''Activo = 1, Desactivado = 0'')
'

EXEC(@Sql)


-- Inserta nuevo parametro en TREC_PARAMETROS para insertar valor de SERVER|IP Reportes

set @process = 'TREC_PARAMETROS - Insert value in par_id 64'
set @Sql ='
INSERT INTO [TREC_PARAMETROS]
           ([par_id]
           ,[par_descripcion]
           ,[par_valor]
           ,[par_detail])
     VALUES
           (64
           ,''ReportesRIA Server|IP''
           ,''''
           ,''Reportes RIA Server|IP for replications'')
'

EXEC(@Sql)


-- Crea nuevo Store procedure para revisar replicaciones

set @process = 'ccsp_AVRSCheckMigration - Create procedure'
set @Sql='
	
		CREATE PROCEDURE [dbo].[ccsp_AVRSCheckMigration]
		AS
		BEGIN
				if not exists(select * from MigrationAVRSReports WHERE status=0)
				begin
					return 1
				end
				else
				begin
					return 0
				end
		END
'

EXEC(@Sql)


set @process= 'Update DB version'
set @Sql='update trec_parametros set par_valor = ''6'' where par_id = 30'
EXEC(@Sql)



	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version

commit tran

	if exists(select * from sys.servers where name = 'CWIP')
    BEGIN
        exec sp_dropserver 'CWIP'
	END

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