USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_CstoCalculaCosto]    Script Date: 27/03/2024 10:53:14 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
  @IDCall int = 0,
  @from AS smalldatetime = NULL,
  @to AS smalldatetime = NULL
  AS
  set nocount on
  declare @minutouno decimal(10,3), @minutoadicional decimal(10,3)
  declare @puerto smallint, @provedor_id smallint
  declare @longitud tinyint, @tipoLlamada_id tinyint
  declare @telefono varchar(20)
  

  if not exists(select * from cstoTarifa) begin
	return (0);
  end

  if @IDCall = 0 -- Para calcular todo
   begin
      if @from is null and @to is null
       begin
          update ccoCallsOut
          --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
          set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
           ,provedor_id = cd.provedor_id
           ,tipoLlamada_id = t.tipoLlamada_id
          from ccoCallsOut cco with(index(IX_ccoCallsOut_7), nolock), ccoDialers cd, cstoTarifa t
          where cco.cal_puerto = cd.puerto
           and cd.provedor_id = t.provedor_id 
           and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cal_telefono)
           and cco.cal_manual <> 1
           return(0)
       end
  
      -- calcula en el rango de fechas, solo los que no tienen costo
      update ccoCallsOut
      --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
      set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
      ,provedor_id = cd.provedor_id
      ,tipoLlamada_id = t.tipoLlamada_id
      from ccoCallsOut cco with(index(IX_ccoCallsOut_8), nolock), ccoDialers cd, cstoTarifa t
      where cco.cal_puerto = cd.puerto
       and cd.provedor_id = t.provedor_id 
       and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cco.cal_telefono)
       and cco.cal_manual <> 1
       and cco.cal_inicio between @from and @to
       and cco.provedor_id is null
       return(0)
   end
  
  select @puerto = cal_puerto, @longitud = len(cal_telefono) , @telefono = cal_telefono 
  from ccoCallsOut with(index(PK_ccoCallsOut), nolock) where cal_id = @idCall
  
  if @puerto = 0
      return(0)
  
  select @tipoLlamada_id = dbo.fnGetTipoLlamada(@telefono)

  select @minutouno = minutouno, @minutoadicional = minutoadicional, @provedor_id = d.provedor_id
  from cstoTarifa t
  inner join ccoDialers d on d.provedor_id = t.provedor_id
  where t.tipollamada_id = @tipoLlamada_id
  and d.puerto = @puerto
  
  update ccoCallsOut with(rowlock) 
  --set costo = @MinutoUno + case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
  set costo = @MinutoUno + case when ISNULL(totalCall_Time,0) > 0 then((ceiling(( ISNULL(totalCall_Time,0) ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
  ,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
  ,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
  where cal_id = @idCall
  
  set nocount off
  