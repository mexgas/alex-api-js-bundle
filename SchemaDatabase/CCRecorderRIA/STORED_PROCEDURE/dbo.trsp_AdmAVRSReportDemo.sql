CREATE PROCEDURE [dbo].[trsp_AdmAVRSReportDemo]
@id_formato int,
@version int,
@call_id int,
@tipo int,
@medio int

AS

BEGIN
       CREATE TABLE #tbl_ReporteConcepto(id int primary key identity(1,1),id_concepto int,concepto varchar(max));
       CREATE TABLE #tbl_ReportePregunta(id int primary key identity(1,1),id_pregunta int,pregunta varchar(max),id_concepto int,respuesta nvarchar(max),peso int,valor int);
       CREATE TABLE #tbl_Reporte(id int primary key identity(1,1),conceptopregunta varchar(max),respuesta varchar(max),puntos nvarchar(max),valorTotal nvarchar(max));

       declare @iter as int
       declare @iter1 as int
       declare @id_concepto int
       declare @respuesta varchar(max)
       declare @idForma as int
       declare @id_grabacion as int
       set @iter=1
       set @iter1=1
       
       if @medio =1
          BEGIN
                IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
                   BEGIN
            
                          set @id_grabacion = (select grab_id from RIA_GRABACION where cal_id=@call_id and tipo_llamada=@tipo)

                   END
                ELSE
                   BEGIN

                          set @id_grabacion = (select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)
            
                   END
          
                set @idForma=(select top 1 id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version order by id_forma desc)
          END
       else
          BEGIN
                set @id_grabacion = @call_id

                set @idForma=(select top 1  id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version order by id_forma desc)
                
          END


       INSERT into #tbl_ReporteConcepto select id_concepto,con_descripcion from RIA_CONCEPTOS where id_formato=@id_formato and version=@version

       while @iter <=(select count(1)  from #tbl_ReporteConcepto)
       begin
              select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter
              INSERT into #tbl_ReportePregunta  SELECT  RIA_PREGUNTAS.id_pregunta, RIA_PREGUNTAS.enunciado_pregunta, RIA_PREGUNTAS.id_concepto,RIA_RESULTADOSFORMA.etiquetas, RIA_RESULTADOSFORMA.peso,RIA_PREGUNTAS.peso
                                         FROM         RIA_PREGUNTAS INNER JOIN
                                          RIA_RESULTADOSFORMA ON RIA_PREGUNTAS.id_pregunta = RIA_RESULTADOSFORMA.id_pregunta
                                          where id_concepto=@id_concepto and RIA_RESULTADOSFORMA.id_forma=@idForma;
       set @iter = @iter+1;
       end

       while @iter1 <= (select count(1)  from #tbl_ReporteConcepto) 
       begin
              INSERT into #tbl_Reporte select concepto,'','','' from #tbl_ReporteConcepto where id=@iter1
              select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter1
             INSERT into #tbl_Reporte select pregunta,respuesta,peso,valor from #tbl_ReportePregunta where id_concepto=@id_concepto
              set @iter1 = @iter1+1;
       end    

       INSERT into #tbl_Reporte
       select 'Total','',convert(nvarchar(max),sum(convert(int,puntos)))as peso,convert(nvarchar(max),sum(convert(int,valorTotal)))as valor From #tbl_Reporte
       
       select * from #tbl_Reporte

END