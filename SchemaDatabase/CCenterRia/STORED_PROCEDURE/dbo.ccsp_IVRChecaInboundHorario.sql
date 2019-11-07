CREATE PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
@inbound_id int
AS
set nocount on
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @Cuantos smallint
declare @bnocturno smallint
declare @tel_noct varchar(14)
declare @tel_maxqueue varchar(14)
declare @tel_maxwait varchar(14)
declare @tel_outservice varchar(14)
declare @tHoldCall int
declare @OutOFService tinyint
declare @Active tinyint
declare @stopRecording bit
declare @MohFiles varchar(8000)
declare @ivr_script smallint, @surveycamid int

    SET DATEFIRST 1

    select @fecha =  getdate()
    select @surveycamid = 0, @ivr_script = 0
    select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
    if ( @dia=1 )     --LUNES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND LUNES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=2   --MARTES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND MARTES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=3   --MIERCOLES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND MIERCOLES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=4   --JUEVES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND JUEVES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=5   --VIERNES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND VIERNES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=6   --SABADO
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND SABADO = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=7   --DOMINGO
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND DOMINGO = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    --- Para ver si esta Activa la Especialidad
    select @Active = count(*)
    from ccInbound
    where Inbound_id = @inbound_id
    and Status =1
    --- Para ver si esta en Operacion o No esta Campaña
    select @OutOFService = count(*)
    from ccInbound
    where Inbound_id = @inbound_id
    and standby = 0
    IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
    BEGIN
--                SI ESTA EN SERVICO
          select  @tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording,
                @tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice, @surveycamid = isnull(cam_id,0)
                from ccInbound I
                Where I.Inbound_id = @inbound_id

          if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

          --Custom MOH Files
          SELECT @MohFiles = COALESCE(@MohFiles + ',', '') + V.msgfile 
          FROM ccInboundMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE Inbound_id = @Inbound_ID and TYPE = 15 ORDER BY orden
    END
    ELSE
    BEGIN
          IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
          BEGIN -- ESPECIALIDAD NO ACTIVA
                select @Cuantos= -1, @tHoldCall =0, @bnocturno ='', @tel_noct ='', @tel_maxqueue='', @tel_maxwait='', @tel_outservice='', @MohFiles=''
                --from ccInbound
                --Where Inbound_id = @inbound_id
          END
          IF ( @Active = 0 )
          BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
                select @Cuantos= -2, @tHoldCall =0, @bnocturno ='', @tel_noct ='', @tel_maxqueue='', @tel_maxwait='', @tel_outservice=tel_outservice, @MohFiles=''
                from ccInbound
                Where Inbound_id = @inbound_id
          END 
    END
    SET DATEFIRST 7

    select 'Cuantos'=@Cuantos, 'tHoldCall'=@tHoldCall, 'bNocturno'=1, 'tel_MaxWait'=@tel_maxwait, 'tel_MaxQueue'=@tel_maxqueue, 'tel_Noct'=@tel_noct, 'tel_outservice'=@tel_outservice, 'stopRecording'=@stopRecording, 'mohFiles'=isnull(@MohFiles,''), 'ivrScript'=@ivr_script 
set nocount off