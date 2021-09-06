/*

Fecha: 2013/10/15
Descripcion: 

* Se modifican store procedures para mejor manejo de informacion en las replicas.
* Fix para trsp_AdmSaveMailConfigInfo al guardar valores de correo electronico

Version requerida: 7

*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 8
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------


-- Se inserta nuevo valor en TREC_PARAMETROS

Set @process = 'trec_parametros - Insert new value in par_id 65'
Set @Sql = '
declare @count int
set @count = (select  count (*) from trec_parametros where par_id = 65)
if @count <= 0 begin
insert trec_parametros(par_id,par_descripcion,par_valor,par_detail) values (65,''Ruta Exporta Grabacion RIA'','''',''Ruta que se utiliza para exportar las grabaciones de CW XION'')
end
'
EXEC(@Sql)


-- Se altera vista de RIA_GRABACION

Set @process = 'trvw_tl_RIA_GRABACION - Alter View'
Set @Sql='

ALTER VIEW [dbo].[trvw_tl_RIA_GRABACION]
AS
SELECT     grab_id, age_id, finicio, duracion, id_repositorio, tipo_llamada, cam_id, calif_id, cal_id, ffin, ani, dni, id_nivel_grito, cal_key, cal_manual, cal_extension
FROM       dbo.RIA_GRABACION

'
EXEC(@Sql)


-- Alteramos algunos Store Procedures para un mejor uso cuando se tienen replicas

--SP trsp_AdmGetSupervisorsForAgent

set @process = 'trsp_AdmGetSupervisorsForAgent - Alter Procedure'
set @Sql='

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
Exec(@Sql)


--SP trsp_AdmGetSupervisorsName

set @process = 'trsp_AdmGetSupervisorsName - Alter Procedure'
Set @Sql='

ALTER PROCEDURE  [dbo].[trsp_AdmGetSupervisorsName]

@user_id int

AS
BEGIN

	SET NOCOUNT ON;


select IsNULL(Nombres,'''') as nombre ,ISNULL(ApellidoPaterno,'''') as apellidopaterno, ISNULL(ApellidoMaterno,'''') as apellidomaterno from ccUsers where user_id = @user_id


END

'
Exec(@Sql)


-- SP trsp_AdmGetMarks

Set @process = 'trsp_AdmGetMarks - Alter Procedure'
Set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmGetMarks]

@cal_id int,
@tipo_llamada int


AS
BEGIN

    SET NOCOUNT ON;

    select a.id_marca,a.user_id,b.login, a.marca, a.tipo_marca
    from RIA_MARCAS a inner join ccUsers b
    on  b.user_id = a.user_id
    where (a.call_id = @cal_id and tipo_llamada = @tipo_llamada)
    order by marca


END
'
Exec(@Sql)


-- SP trsp_AdmPCIGetCamp

Set @process = 'trsp_AdmPCIGetCamp - Alter Procedure'
Set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmPCIGetCamp]

@User_id int 

AS
BEGIN

	 
	 select a1.cam_id, a1.cam_Descripcion , a3.frame, isnull(a4.Xtime,0) as Xtime,  isnull(a4.ActiveXtime,0) as ActiveXtime, isnull(a4.onOff,0) as OnOff
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
     left join RIA_PCI_CAMP_SETTINGS a4 on (a4.cam_id = a1.cam_id) 
	 --where a1.cam_id in (select cam_id from fGet_CampAcd_Area (@User_id, 1))
     where a1.cam_id in (select cam_id from fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion

END

'
Exec(@Sql)


-- SP trsp_AdmPCIGetACD

Set @process = 'trsp_AdmPCIGetACD - Alter Procedure'
Set @Sql='
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
Exec(@Sql)


-- SP trsp_AdmPCIGetDefaultList

Set @process = 'trsp_AdmPCIGetDefaultList - Alter Procedure'
Set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmPCIGetDefaultList]

@ListType int


AS
BEGIN

declare @Idiom int

	SET NOCOUNT ON;

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
Exec(@Sql)

-- SP trspAdmRecordingInfo

Set @process = 'trspAdmRecordingInfo - Alter Procedure'
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
CASE WHEN b.tipo_llamada=1 THEN b.ani ELSE b.ani END,
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
WHERE b.grab_id=@grab_id
END
'
EXEC (@Sql)


-- SP trspAdmRecordingsOfDay

Set @process = 'trspAdmRecordingsOfDay - Alter Procedure'
set @Sql='


ALTER PROCEDURE  [dbo].[trspAdmRecordingsOfDay]
@idAgent as INT
AS
set nocount on
DECLARE @CallType as INT

BEGIN
	(SELECT     a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN a.ani ELSE a.ani END AS Expr1, 
                      b.cam_descripcion AS Expr2, 
                      CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE WHEN a.tipo_llamada = 2 THEN d .description ELSE e.description END AS Expr4, 
                     isnull(a.id_nivel_grito,-1),@idAgent as age_id, isnull (i.total_forma,0) as rating,j.Computer, k.Nombres AS Agente
	FROM         RIA_GRABACION AS a INNER JOIN
                      ccCamps AS b ON a.cam_id = b.cam_id LEFT OUTER JOIN
                      ccTipoCalifOUT AS d ON a.calif_id = d.calif_id LEFT OUTER JOIN
                      ccTipoCalif AS e ON a.calif_id = e.calif_id LEFT OUTER JOIN
                      RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito LEFT OUTER JOIN
					  RIA_FORMACALIF AS i on i.id_grabacion = a.grab_id left join 
					  ccPosicion j on j.pos_id = a.cal_extension * -1 left join 
					  ccUsers k on k.User_id = @idAgent
WHERE     (a.age_id = @idAgent) AND (a.tipo_llamada=2) AND(DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))

UNION ALL

	(SELECT     a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN a.ani ELSE a.ani END AS Expr1, 
                      c.descripcion AS Expr2, 
                      CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE WHEN a.tipo_llamada = 2 THEN d .description ELSE e.description END AS Expr4, 
                      isnull(a.id_nivel_grito,-1),@idAgent as age_id, isnull (i.total_forma,0) as rating, j.Computer, k.Nombres AS Agente
	FROM         RIA_GRABACION AS a INNER JOIN
                      ccInbound AS c ON a.cam_id = c.Inbound_id LEFT OUTER JOIN
                      ccTipoCalifOUT AS d ON a.calif_id = d.calif_id LEFT OUTER JOIN
                      ccTipoCalif AS e ON a.calif_id = e.calif_id LEFT OUTER JOIN
                      RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito LEFT OUTER JOIN
					  RIA_FORMACALIF AS i on i.id_grabacion = a.grab_id left join 
					  ccPosicion j on j.pos_id = a.cal_extension * -1 left join 
					  ccUsers k on k.User_id = @idAgent
WHERE     (a.age_id = @idAgent) AND (a.tipo_llamada=1) AND (DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))
END


'
EXEC (@Sql)


-- SP trsp_AdmRecSearchNodeWorkgroup

Set @process = 'trsp_AdmRecSearchNodeWorkgroup - Alter Procedure'
set @Sql = '

ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]

@User_id int

AS
BEGIN

	SET NOCOUNT ON;


select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsers b
on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
where a.user_id = @User_id order by 1


END

'
EXEC (@Sql)

-- SP trsp_AdmRecSearchNodeCamp

Set @process = 'trsp_AdmRecSearchNodeCamp - Alter Procedure'
set @Sql = '

ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeCamp]

@Workgroup int

AS
BEGIN

	SET NOCOUNT ON;

select a.idCampEsp, b.cam_descripcion, d.frame from ccRIACampEspWG a
inner join ccCamps b on b.cam_id = a.idCampEsp
inner join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
inner join ccRIAGraphics d on d.graphic_id = c.graphic_id
where a.IDWG = @Workgroup and a.Tipo = 1

END
'
EXEC (@Sql)


-- SP trsp_AdmRecSearchNodeCalif

Set @process = 'trsp_AdmRecSearchNodeCalif - Alter Procedure'
set @Sql = '


ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeCalif]

@CamACD_id int,
@CallType int

AS
BEGIN

	SET NOCOUNT ON;


IF @CallType = 0 

BEGIN

select a.calif_id, b.Description from ccCalifCamp a
inner join ccTipoCalif b 
on b.calif_id = a.calif_id and b.Calif_Status = 1
where cam_id = @CamACD_id and a.tipo = 0

END

ELSE IF @CallType = 1 

BEGIN 

select a.calif_id, b.Description from ccCalifCamp a
inner join ccTipoCalifOUT b 
on b.calif_id = a.calif_id and b.CalifOUT_Status = 1
where cam_id = @CamACD_id and a.tipo = 1


END

END

'
EXEC (@Sql)


--SP trsp_AdmRecSearchNodeAgent

Set @process = 'trsp_AdmRecSearchNodeAgent - Alter Procedure'
set @Sql = '


ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeAgent] 

@Workgroup int

AS
BEGIN

	SET NOCOUNT ON;

select a.User_id, a.Nombres, b.IDWG from ccUsers a
inner join ccRIAWorkGroupUsers b
on b.IDWG = @Workgroup
where a.User_id = b.User_id and a.TipoUser_id = 1

END

'
EXEC (@Sql)


-- SP trsp_AdmRecSearchOneDay

Set @process = 'trsp_AdmRecSearchOneDay - Alter Procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]

@Sup_id int

AS
BEGIN

	SET NOCOUNT ON;

select  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, a.cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer, 
isnull (d.total_forma,0) as total_forma, a.id_repositorio, CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion

from trvw_tl_RIA_GRABACION a 
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
Exec(@Sql)


-- SP trsp_AdmRecGetWGforSearch

Set @process = 'trsp_AdmRecGetWGforSearch - Alter Procedure'
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
Exec(@Sql)


-- SP trsp_AdmRecSearchCalID

Set @process = 'trsp_AdmRecSearchCalID - Alter Procedure'
set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
	-- Add the parameters for the stored procedure here
@Sup_id int,
@CalID int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from trvw_tl_RIA_GRABACION a
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
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))
UNION ALL
select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
                      + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
from trvw_tl_RIA_GRABACIONCONSULTA a
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
inner join  ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))
order by finicio desc

END

'
Exec(@Sql)


-- SP trsp_AdmRecSearchAllRecs

Set @process = 'trsp_AdmRecSearchAllRecs - Alter Procedure'
Set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]

@Sup_id int,
@Finicio datetime,
@Ffin datetime

AS
BEGIN

	SET NOCOUNT ON;

declare @fecha  datetime

set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

if (@Finicio >= @fecha and @Ffin >= @fecha) 
	begin
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
        from trvw_tl_RIA_GRABACION a
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
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
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

		order by finicio desc
	end
else if (@Finicio < @fecha and @Ffin < @fecha ) 
	begin
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
        from trvw_tl_RIA_GRABACIONCONSULTA a
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
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
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

		order by finicio desc
	end
else if (@Finicio <= @fecha and @Ffin >= @fecha ) 
	begin
		
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
        from trvw_tl_RIA_GRABACION a
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
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
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
		UNION ALL	
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio, a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (d.total_forma,0) as total_forma, a.id_repositorio,CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) 
							  + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion
        from trvw_tl_RIA_GRABACIONCONSULTA a
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
			   (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b
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

		order by finicio desc	
	end
END
'
Exec(@Sql)


-- SP trsp_AdmX

Set @process = 'trsp_AdmX - Alter Procedure'
Set @Sql='
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
   DECLARE @fecha  datetime
   
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
  
   SET @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

    if (@Finicio1 >= @fecha)
        BEGIN
            DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,isnull(cal_manual,0) as cal_manual,
                     CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 / 60), 2)
                      + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
                     FROM trvw_tl_RIA_GRABACION   
                     where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
            OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            WHILE (@@FETCH_STATUS = 0 ) BEGIN
                SET @vt3 = (SELECT Login from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt4 = (SELECT Nombres from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt5 = (SELECT ApellidoPaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt6 = (SELECT ApellidoMaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt7 = (SELECT Description from trvw_tl_ccTipoCalif where calif_id=@calif_id)
                SET @vt8 = (SELECT b.computer  as pos_id from trvw_tl_RIA_GRABACION a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @tipoUs = (SELECT TipoUser_id from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from trvw_tl_RIA_GRABACION a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
               
                IF(@tipo_llamada=1 and @tipoUs=1)
                  BEGIN          
                   SET @vt1 = (SELECT descripcion from trvw_tl_ccInbound where Inbound_id=@cam_id)
                   SET @vt22 = (SELECT Description from ccTipoCalif where calif_id=@calif_id)
                   END
                ELSE IF(@tipo_llamada=2 and @tipoUs=1)
                  BEGIN
                    SET @vt1 = (SELECT cam_descripcion from trvw_tl_ccCamps where cam_id=@cam_id)
                    SET @vt22 = (SELECT Description from ccTipoCalifOUT where calif_id=@calif_id)
                  END
               
                INSERT INTO @TablaTemporal(grab_id,finicio,duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,ffin,id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion)values(@grab_id,@finicio,@duracion,@tipo_llamada,@cam_id,@vt1,@age_id,@vt3,@vt4,@vt5,@vt6,@calif_id,@vt7,@cal_id,@id_repositorio,DATEADD(second,@duracion,@finicio),@id_nivel_grito,@ani,@dni,@cal_key,@cal_manual,@vt8,@vt9,@vt10,@vt22,@formato_duracion)
               
                SET @vt1= '' ''
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
        END
    ELSE IF (@Finicio1 < @fecha)
        BEGIN
            DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,isnull(cal_manual,0) as cal_manual,
                     CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 / 60), 2)
                      + '':'' + RIGHT(''0'' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
                     FROM trvw_tl_RIA_GRABACIONCONSULTA   
                     where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCRIACampEspWG a inner join  ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
            OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            WHILE (@@FETCH_STATUS = 0 ) BEGIN
                SET @vt3 = (SELECT Login from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt4 = (SELECT Nombres from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt5 = (SELECT ApellidoPaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt6 = (SELECT ApellidoMaterno from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt7 = (SELECT Description from trvw_tl_ccTipoCalif where calif_id=@calif_id)
                SET @vt8 = (SELECT b.computer  as pos_id from trvw_tl_RIA_GRABACIONCONSULTA a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @tipoUs = (SELECT TipoUser_id from trvw_tl_ccUsers where User_id=@age_id)
                SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from trvw_tl_RIA_GRABACIONCONSULTA a,ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
               
                IF(@tipo_llamada=1 and @tipoUs=1)
                  BEGIN          
                   SET @vt1 = (SELECT descripcion from trvw_tl_ccInbound where Inbound_id=@cam_id)
                   SET @vt22 = (SELECT Description from ccTipoCalif where calif_id=@calif_id)
                   END
                ELSE IF(@tipo_llamada=2 and @tipoUs=1)
                  BEGIN
                    SET @vt1 = (SELECT cam_descripcion from trvw_tl_ccCamps where cam_id=@cam_id)
                    SET @vt22 = (SELECT Description from ccTipoCalifOUT where calif_id=@calif_id)
                  END
           
                INSERT INTO @TablaTemporal(grab_id,finicio,duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,ffin,id_nivel_grito,ani,dni,cal_key,cal_manual,Computer,pos_id,total_forma,score,formato_duracion)values(@grab_id,@finicio,@duracion,@tipo_llamada,@cam_id,@vt1,@age_id,@vt3,@vt4,@vt5,@vt6,@calif_id,@vt7,@cal_id,@id_repositorio,DATEADD(second,@duracion,@finicio),@id_nivel_grito,@ani,@dni,@cal_key,@cal_manual,@vt8,@vt9,@vt10,@vt22,@formato_duracion)
               
                SET @vt1= '' ''
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
        END
  
       SELECT grab_id,CONVERT(VARCHAR(24),finicio,120) as ''finicio'',duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,CONVERT(VARCHAR(24),ffin,120) as ''ffin'',id_nivel_grito,ani,dni,cal_key,isnull(cal_manual,0) as cal_manual,Computer,pos_id,total_forma,score,formato_duracion
    FROM @TablaTemporal
    ORDER BY finicio,duracion
END

'
Exec(@Sql)


-- SP trsp_AdmSaveMailConfigInfo

Set @process = 'trsp_AdmSaveMailConfigInfo - Alter Procedure'
Set @Sql='
ALTER PROCEDURE [dbo].[trsp_AdmSaveMailConfigInfo]
	-- Add the parameters for the stored procedure here

@MailType as tinyint,
@Server as varchar(50),
@Port as int,
@User as varchar(50),
@Pass as varchar(50),
@MailFile as varchar(50),
@Domain as varchar(50),
@Ssl as varchar(50),
@Authentication as varchar(50),
@From as nvarchar(80),
@Display as nvarchar(250)

AS
BEGIN

	SET NOCOUNT ON;

Declare @count as smallint

set @count = (select count(*) from TREC_PARAMMAIL)


IF @count > 0 BEGIN

Update TREC_PARAMMAIL set MailType=@MailType,[Server]=@Server,Port=@Port,[User]=@User,
Pass=@Pass,MailFile=@MailFile,Domain=@Domain,Ssl=@Ssl,Authentication=@Authentication, [From] =@User, Display=@Display

Update TREC_PARAMETROS set par_valor = @Server where par_id = 6
Update TREC_PARAMETROS set par_valor = @Display where par_id = 24

END

ELSE BEGIN

Insert TREC_PARAMMAIL(MailType,[Server],Port,[User],Pass,MailFile,Domain,Ssl,Authentication,[From],Display) values
(@MailType,@Server,@Port,@User,@Pass,@MailFile,@Domain,@Ssl,@Authentication,@User,@Display)

Update TREC_PARAMETROS set par_valor = @Server where par_id = 6
Update TREC_PARAMETROS set par_valor = @Display where par_id = 24

END

END

'
EXEC(@Sql)


-- Se altera procedure trsp_muevegrabaciones

Set @process = 'trsp_muevegrabaciones - Alter Procedure'
Set @Sql='
ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
AS
BEGIN
	declare @fecha datetime

	set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

	SET IDENTITY_INSERT RIA_GRABACIONCONSULTA ON
	
	INSERT INTO [RIA_GRABACIONCONSULTA] (
	grab_id,
	cli_id,
	age_id,
	puerto_id,
	tipo_grab_id,
	age_id_rec,
	ffin,
	finicio,
	ani,
	tamano,
	dni,
	duracion,
	pos_pc,
	extension,
	razon_id,
	nombre_archivo,
	info1,
	info2,
	info3,
	info4,
	info5,
	borra_id,
	fvalida,
	fvalida2,
	tipo_Llamada,
	cam_id,
	calif_id,
	id_repositorio,
	id_nivel_grito,
	cal_id,
	cal_key,
	cal_manual,
	cal_fcallback,
	cal_extension,
	cal_whoHung,
	cal_whoRec,
	id_plantilla,
	dni_id,
	id_rep_video,
	extra_info,
	extra_info2
	) SELECT 
	grab_id,
	cli_id,
	age_id,
	puerto_id,
	tipo_grab_id,
	age_id_rec,
	ffin,
	finicio,
	ani,
	tamano,
	dni,
	duracion,
	pos_pc,
	extension,
	razon_id,
	nombre_archivo,
	info1,
	info2,
	info3,
	info4,
	info5,
	borra_id,
	fvalida,
	fvalida2,
	tipo_Llamada,
	cam_id,
	calif_id,
	id_repositorio,
	id_nivel_grito,
	cal_id,
	cal_key,
	cal_manual,
	cal_fcallback,
	cal_extension,
	cal_whoHung,
	cal_whoRec,
	id_plantilla,
	dni_id,
	id_rep_video,
	extra_info,
	extra_info2
	FROM [RIA_GRABACION] WHERE [finicio] < @fecha;
	
	SET IDENTITY_INSERT RIA_GRABACIONCONSULTA OFF

	DELETE FROM RIA_GRABACION WHERE [finicio] < @fecha;
END
'
EXEC(@Sql)



set @process = 'Update DB version'
set @Sql='
 update trec_parametros set par_valor = ''8'' where par_id = 30 
'
Exec(@Sql)
	------------------ fin SCRIPT @Sql ------------------


	commit tran

--- Se quita link server AVRS-CW si es que el cliente lo tiene

if exists(select * from sys.servers where name = 'CWIP')
     BEGIN
        exec sp_dropserver 'CWIP'
	 END
----------------------------------------------------------------

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