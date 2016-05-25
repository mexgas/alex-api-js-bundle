/*

Fecha: 2013/09/30
Descripcion: 	

Version requerida: 6
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 7
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)

	---------------- inicio SCRIPT @Sql ----------------


-- Se crea nueva vista para RIA_GRABACIONCONSULTA

set @process='trvw_tl_RIA_GRABACIONCONSULTA - Create view'
set @Sql='

CREATE VIEW [dbo].[trvw_tl_RIA_GRABACIONCONSULTA]
AS
SELECT     grab_id, age_id, ffin, finicio, ani, dni, duracion, id_repositorio, id_nivel_grito, tipo_llamada, cam_id, calif_id, cal_id, cal_key, cal_manual, cal_extension
FROM         dbo.RIA_GRABACIONCONSULTA

'
EXEC (@Sql)

--- Se crea nuevo store trsp_AgtGetRepositoryCallHistory para poder consultar repositorios de llamadas en el agente

set @process ='trsp_AgtGetRepositoryCallHistory - Create procedure'
set @Sql = '
CREATE PROCEDURE  [dbo].[trsp_AgtGetRepositoryCallHistory]

@CallID int,
@Tipo_llamada smallint


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @IDRepositorio int

set @IDRepositorio = (select id_repositorio from RIA_GRABACION where cal_id = @CallID and tipo_llamada = @Tipo_llamada UNION select id_repositorio from RIA_GRABACIONCONSULTA where cal_id = @CallID and tipo_llamada = @Tipo_llamada)

select isnull(dirvirtual_audio,'''') as dirvirtual_audio  from TREC_REPOSITORIOS where id_repositorio = @IDRepositorio

END
'
EXEC (@Sql)


-- Se crea nuevo store procedure trsp_AgtHasRecordingMark para saber si la llamada contiene marcas en el modulo del agente

set @process= 'trsp_AgtHasRecordingMark - Create procedure'
set @Sql='

CREATE PROCEDURE [dbo].[trsp_AgtHasRecordingMark]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @count int
set @count =(select COUNT(*) from ria_marcas where call_id = @cal_id and tipo_llamada = @tipo_llamada)

if @count>1 begin
select ''1''
end
else
begin
select ''0''
end

END

'
EXEC (@SQL)


-- Se altera store procedure trsp_AdmGetAllRepositories para fix al guardar repositorios de AVRS

set @process= 'trsp_AdmGetAllRepositories - Alter procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
	-- Add the parameters for the stored procedure here
@Mode int
-- Mode 1 para busqueda de grabaciones
-- Mode 2 para configuracion de repositorios

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF @Mode = 1
Begin

select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes  from TREC_REPOSITORIOS order by id_repositorio
	End
Else IF @Mode =2
	Begin
	
select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes  from TREC_REPOSITORIOS order by id_repositorio

End


END

'
EXEC (@Sql)



-- Se altera store procedure trsp_AdmSaveCWRepConfigInfo para fix al guardar info de repositorios

set @process = 'trsp_AdmSaveCWRepConfigInfo - Alter procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmSaveCWRepConfigInfo]
	-- Add the parameters for the stored procedure here

@id_repositorio as tinyint,
@Audio as nvarchar(250),
@AudioRep as nvarchar(250),
@AudioLocal as nvarchar(250),
@Video as nvarchar(250),
@VideoRep as nvarchar(250),
@VideoLocal as nvarchar(250),
@ImagenesRep as nvarchar(250)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



Update CCRecorderRIA.dbo.TREC_REPOSITORIOS set ruta_repositorio = @Audio, dirvirtual_audio=@AudioRep, ruta_local=@AudioLocal, 
ruta_rep_video = @Video, dirvirtual_video=@VideoRep, ruta_local_video=@VideoLocal, ruta_imagenes = @ImagenesRep where id_repositorio = @id_repositorio

END

'
EXEC (@Sql)



-- Se altera store procedure trsp_AdmGetMarks para obtener marcas del agente

set @process='trsp_AdmGetMarks - Alter procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmGetMarks]
    -- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int


AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;


    select a.id_marca,a.user_id,b.login, a.marca, a.tipo_marca
    from CCRecorderRIA.dbo.RIA_MARCAS a inner join ccUsers b
    on  b.user_id = a.user_id
    where (a.call_id = @cal_id and tipo_llamada = @tipo_llamada)
    order by marca


END
'
EXEC (@Sql)


-- Se altera store procedure para guardar las marcas del supervisor

set @process ='trsp_AdmSaveSupervisorMarks - Alter procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmSaveSupervisorMarks]
    -- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@user_id int,
@marca nvarchar(MAX)


AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @grab_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

insert CCRecorderRIA.dbo.RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grab_id,@user_id,@marca,2,@tipo_llamada,@cal_id )

END
'
EXEC (@Sql)



-- Se optimiza store procedure trsp_AdmRecSearchAllRecs para busqueda de grabaciones

set @process='trsp_AdmRecSearchAllRecs - Alter procedure'
set @Sql='

ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
	-- Add the parameters for the stored procedure here
@Sup_id int,
@Finicio datetime,
@Ffin datetime

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
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
		left join CCenterRIA.dbo.ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join CCRecorderRIA.dbo.RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		CCenterRia.dbo.ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		CCenterRia.dbo.ccTipoCalif AS f ON a.calif_id = f.calif_id
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
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
		left join CCenterRIA.dbo.ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join CCRecorderRIA.dbo.RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		CCenterRia.dbo.ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		CCenterRia.dbo.ccTipoCalif AS f ON a.calif_id = f.calif_id
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
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
		left join CCenterRIA.dbo.ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join CCRecorderRIA.dbo.RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		CCenterRia.dbo.ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		CCenterRia.dbo.ccTipoCalif AS f ON a.calif_id = f.calif_id
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
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
		left join CCenterRIA.dbo.ccPosicion b 
		on b.pos_id = a.cal_extension * -1
		left join CCRecorderRIA.dbo.RIA_FORMACALIF d
		on d.id_grabacion = a.grab_id left join
		CCenterRia.dbo.ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
		CCenterRia.dbo.ccTipoCalif AS f ON a.calif_id = f.calif_id
		where 
		(a.finicio BETWEEN  @Finicio AND @Ffin) 
			 and
			(
			  (Tipo_llamada = 2 and a.cam_id in 
			   (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				  on b.User_id = @Sup_id  inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				  where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
				)
			  )
			  OR 
			 (Tipo_llamada = 1 and a.cam_id in
			  (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
				on b.User_id = @Sup_id inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG
				where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
			   )
			 )
		   )

		order by finicio desc	
	end
END
'
EXEC (@Sql)


-- Se optimiza store procedure trsp_AdmRecSearchCalID para busqueda de grabaciones por call id

set @process='trsp_AdmRecSearchCalID - Alter procedure'
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
left join CCenterRIA.dbo.ccPosicion b
on b.pos_id = a.cal_extension * -1
left join CCRecorderRIA.dbo.RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
CCenterRia.dbo.ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
CCenterRia.dbo.ccTipoCalif AS f ON a.calif_id = f.calif_id
where 
(a.cal_id = @CalID)
and(
(Tipo_llamada = 2 and
a.cam_id in 
(select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a
inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join CCenterRIA.dbo.ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1))
OR 
(Tipo_llamada = 1 and
a.cam_id in
(select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a
inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join CCenterRIA.dbo.ccRIACat_WorkGroup c
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
left join CCenterRIA.dbo.ccPosicion b
on b.pos_id = a.cal_extension * -1
left join CCRecorderRIA.dbo.RIA_FORMACALIF d
on d.id_grabacion = a.grab_id left join
CCenterRia.dbo.ccTipoCalifOUT AS e ON a.calif_id = e.calif_id left join
CCenterRia.dbo.ccTipoCalif AS f ON a.calif_id = f.calif_id
where 
(a.cal_id = @CalID)
and(
(Tipo_llamada = 2 and
a.cam_id in 
(select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a
inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join CCenterRIA.dbo.ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 1 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1))
OR 
(Tipo_llamada = 1 and
a.cam_id in
(select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a
inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b
on b.User_id = @Sup_id
inner join CCenterRIA.dbo.ccRIACat_WorkGroup c
on c.IDWG = a.IDWG
where a.Tipo = 0 and  a.IDWG = b.IDWG and c.StatusWorkGroup = 1
)))
order by finicio desc

END

'
EXEC (@Sql)


-- Se optimiza store procedure trsp_AdmX para busqueda de grabaciones en timeline

set @process='trsp_AdmX - Alter procedure'
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
                     FROM CCRecorderRIA.dbo.trvw_tl_RIA_GRABACION   
                     where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
            OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            WHILE (@@FETCH_STATUS = 0 ) BEGIN
                SET @vt3 = (SELECT Login from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt4 = (SELECT Nombres from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt5 = (SELECT ApellidoPaterno from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt6 = (SELECT ApellidoMaterno from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt7 = (SELECT Description from CCRecorderRIA.dbo.trvw_tl_ccTipoCalif where calif_id=@calif_id)
                SET @vt8 = (SELECT b.computer  as pos_id from CCRecorderRIA.dbo.trvw_tl_RIA_GRABACION a,CCenterRIA.dbo.ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @tipoUs = (SELECT TipoUser_id from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from CCRecorderRIA.dbo.trvw_tl_RIA_GRABACION a,CCenterRIA.dbo.ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id)
               
                IF(@tipo_llamada=1 and @tipoUs=1)
                  BEGIN          
                   SET @vt1 = (SELECT descripcion from CCRecorderRIA.dbo.trvw_tl_ccInbound where Inbound_id=@cam_id)
                   SET @vt22 = (SELECT Description from CCenterRIA.dbo.ccTipoCalif where calif_id=@calif_id)
                   END
                ELSE IF(@tipo_llamada=2 and @tipoUs=1)
                  BEGIN
                    SET @vt1 = (SELECT cam_descripcion from CCRecorderRIA.dbo.trvw_tl_ccCamps where cam_id=@cam_id)
                    SET @vt22 = (SELECT Description from CCenterRIA.dbo.ccTipoCalifOUT where calif_id=@calif_id)
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
                     FROM CCRecorderRIA.dbo.trvw_tl_RIA_GRABACIONCONSULTA   
                     where (finicio between @Finicio1 and @Finicio2) and cam_id in (select distinct a.IdCampEsp from CCenterRIA.dbo.CCRIACampEspWG a inner join  CCenterRIA.dbo.ccRIAWorkGroupUsers b  on b.User_id = @Sup_id  inner join CCenterRIA.dbo.ccRIACat_WorkGroup c on c.IDWG = a.IDWG  where  a.IDWG = b.IDWG and c.StatusWorkGroup = 1)
            OPEN ElCursorI FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            WHILE (@@FETCH_STATUS = 0 ) BEGIN
                SET @vt3 = (SELECT Login from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt4 = (SELECT Nombres from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt5 = (SELECT ApellidoPaterno from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt6 = (SELECT ApellidoMaterno from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt7 = (SELECT Description from CCRecorderRIA.dbo.trvw_tl_ccTipoCalif where calif_id=@calif_id)
                SET @vt8 = (SELECT b.computer  as pos_id from CCRecorderRIA.dbo.trvw_tl_RIA_GRABACIONCONSULTA a,CCenterRIA.dbo.ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @tipoUs = (SELECT TipoUser_id from CCRecorderRIA.dbo.trvw_tl_ccUsers where User_id=@age_id)
                SET @vt9 = (SELECT isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id from CCRecorderRIA.dbo.trvw_tl_RIA_GRABACIONCONSULTA a,CCenterRIA.dbo.ccPosicion b  where b.pos_id = a.cal_extension * -1 and a.grab_id=@grab_id )
                SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id)
               
                IF(@tipo_llamada=1 and @tipoUs=1)
                  BEGIN          
                   SET @vt1 = (SELECT descripcion from CCRecorderRIA.dbo.trvw_tl_ccInbound where Inbound_id=@cam_id)
                   SET @vt22 = (SELECT Description from CCenterRIA.dbo.ccTipoCalif where calif_id=@calif_id)
                   END
                ELSE IF(@tipo_llamada=2 and @tipoUs=1)
                  BEGIN
                    SET @vt1 = (SELECT cam_descripcion from CCRecorderRIA.dbo.trvw_tl_ccCamps where cam_id=@cam_id)
                    SET @vt22 = (SELECT Description from CCenterRIA.dbo.ccTipoCalifOUT where calif_id=@calif_id)
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
EXEC (@Sql)


set @process='Update DB version'
set @Sql='update trec_parametros set par_valor = ''7'' where par_id = 30'
EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	
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