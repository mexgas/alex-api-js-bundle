CREATE PROCEDURE [dbo].[trsp_AdmX]

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
   SET @ffin=' '
   SET @finicio=' '
   SET @duracion=' '
   SET @id_repositorio=' '
   SET @tipo_llamada=0
   SET @cam_id=' '
   SET @calif_id=' '
   SET @cal_id=' '
  
   SET @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

    if (@Finicio1 >= @fecha)
        BEGIN
            DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,isnull(cal_manual,0) as cal_manual,
                     CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(duracion / 3600) + ':' + RIGHT('0' + RTRIM(duracion % 3600 / 60), 2)
                      + ':' + RIGHT('0' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
                     FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3))   
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
                --SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
                SET @vt10 = (select avg(r.total_forma) from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif where id_grabacion=@grab_id group by id_grabacion,id_formato)  t 
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion) 
			   
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
               
                SET @vt1= ' '
                SET @vt3= ' '
                SET @vt4= ' '
                SET @vt5= ' '
                SET @vt6= ' '
                SET @vt7= ' '
                SET @vt8= ' '
                SET @vt9= ' '
                SET @vt10= ' '
                SET @vt22= ' '
                SET @tipoUs= ' '
                FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            END
            CLOSE ElCursorI
            DEALLOCATE ElCursorI
        END
    ELSE IF (@Finicio1 < @fecha)
        BEGIN
            DECLARE ElCursorI CURSOR STATIC LOCAL FORWARD_ONLY FOR
                     SELECT grab_id,age_id,ffin,finicio,duracion,id_repositorio,isnull(id_nivel_grito,-1) as id_nivel_grito,tipo_llamada,cam_id,calif_id,ani,dni,cal_id,cal_key,isnull(cal_manual,0) as cal_manual,
                     CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(duracion / 3600) + ':' + RIGHT('0' + RTRIM(duracion % 3600 / 60), 2)
                      + ':' + RIGHT('0' + RTRIM(duracion % 3600 % 60), 2) AS formato_duracion
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
                --SET @vt10 = (SELECT isnull (total_forma,0) as total_forma from RIA_FORMACALIF where id_grabacion = @grab_id)
			   SET @vt10 = (select avg(r.total_forma) from ria_formacalif r inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif where id_grabacion=@grab_id group by id_grabacion,id_formato)  t 
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion) 
			   
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
               
                SET @vt1= ' '
                SET @vt3= ' '
                SET @vt4= ' '
                SET @vt5= ' '
                SET @vt6= ' '
                SET @vt7= ' '
                SET @vt8= ' '
                SET @vt9= ' '
                SET @vt10= ' '
                SET @vt22= ' '
                SET @tipoUs= ' '
                FETCH NEXT FROM ElCursorI INTO @grab_id,@age_id,@ffin,@finicio,@duracion,@id_repositorio,@id_nivel_grito,@tipo_llamada,@cam_id,@calif_id,@ani,@dni,@cal_id,@cal_key,@cal_manual,@formato_duracion
            END
            CLOSE ElCursorI
            DEALLOCATE ElCursorI
        END
  
       SELECT grab_id,CONVERT(VARCHAR(24),finicio,120) as 'finicio',duracion,tipo_llamada,cam_id,descipcion,user_idd,loginn,Nombres,ApellidoPaterno,ApellidoMaterno,calif_id,descripcionC,cal_id,id_repositorio,CONVERT(VARCHAR(24),ffin,120) as 'ffin',id_nivel_grito,ani,dni,cal_key,isnull(cal_manual,0) as cal_manual,Computer,pos_id,total_forma,score,formato_duracion
    FROM @TablaTemporal
    ORDER BY finicio,duracion
END