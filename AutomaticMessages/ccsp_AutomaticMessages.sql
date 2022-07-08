USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_AutomaticMessages]    Script Date: 06/07/2022 10:45:24 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_AutomaticMessages]
@command smallint, -- 1=Insert, 2=Delete
@msg_id varchar(255)=null,
@campIO_id int=null,
@type tinyint=null,
@campType int=null
as
set nocount on

declare @maxOrden int, @campName varchar(max), @num int
declare @T_all as table (id int, msg_id int)

if @campType=0
    set @campName = (select descripcion from ccInbound where Inbound_id=@campIO_id)
else
    set @campName = (select cam_descripcion from ccCamps where cam_id=@campIO_id)

    If @command=1
     begin
        if @campType=0 
         begin
			select @maxOrden = max(orden) from ccInboundMsgs where Inbound_id=@campIO_id and type=@type

			select @num = case when @maxOrden is null then 1 else 0 end
			set @maxOrden =ISNULL(@maxOrden,0)

            insert @T_all 
            select ROW_NUMBER() OVER(ORDER BY A.id ASC)-@num AS Row#,
            A.value from dbo.fn_RIASplitDelimited(@msg_id, ',') A
            left join ccInboundMsgs B on A.Value=B.Msg_id and B.Inbound_id=@campIO_id and B.Type=@type
            where B.Inbound_id  is null

            insert into ccInboundMsgs (msg_id, inbound_id, orden, type)
            select B.msg_id, @campIO_id as inbound_id, @maxOrden+B.id as orden,@type as type 
            from  @T_all B
            where msg_id not in(select Msg_id from ccInboundMsgs where Inbound_id=@campIO_id and Type=@type)

            select @campName
         end

        if @campType=1 
         begin
			select @maxOrden = max(orden) from ccCampsMsgs where cam_id=@campIO_id and type=@type

			select @num = case when @maxOrden is null then 1 else 0 end
			set @maxOrden =ISNULL(@maxOrden,0)

            insert @T_all 
            select ROW_NUMBER() OVER(ORDER BY A.id ASC)-@num AS Row#,
            A.value from dbo.fn_RIASplitDelimited(@msg_id, ',') A
            left join ccCampsMsgs B on A.Value=B.Msg_id and B.cam_id=@campIO_id and B.Type=@type
            where B.cam_id  is null

            insert into ccCampsMsgs(msg_id, cam_id, orden, type)
            select B.msg_id, @campIO_id as cam_id, @maxOrden+B.id as orden,@type as type 
            from  @T_all B
            where msg_id not in(select Msg_id from ccCampsMsgs where cam_id=@campIO_id and Type=@type)

            select @campName
         end
     end

    if @command=2
     begin
        if @campType=0
        begin
            delete im from ccInboundMsgs im
            where Msg_id IN(select Value from dbo.fn_RIASplitDelimited(@msg_id, ',')) and Inbound_id=@campIO_id and Type=@type

            insert @T_all
            select ROW_NUMBER() OVER(ORDER BY B.orden ASC)-1 AS Row#,
            b.Msg_id from ccInboundMsgs B
            where B.Inbound_id=@campIO_id and B.Type=@type
            order by orden

            UPDATE ccInboundMsgs SET orden = a.id
            FROM ccInboundMsgs IM
            INNER JOIN @T_all A ON IM.Msg_id = A.msg_id
            WHERE IM.Inbound_id=@campIO_id and IM.Type=@type

            select @campName
        end

        if @campType=1
        begin
            delete cm from ccCampsMsgs cm
            where Msg_id IN(select Value from dbo.fn_RIASplitDelimited(@msg_id, ',')) and cam_id=@campIO_id and Type=@type

            insert @T_all
            select ROW_NUMBER() OVER(ORDER BY B.orden ASC)-1 AS Row#,
            b.Msg_id from ccCampsMsgs B 
            where B.cam_id=@campIO_id and B.Type=@type
            order by orden

            UPDATE ccCampsMsgs SET orden = a.id
            FROM ccCampsMsgs CM
            INNER JOIN @T_all A ON CM.Msg_id = A.msg_id
            WHERE CM.cam_id=@campIO_id and CM.Type=@type

            select @campName
        end
     end


set nocount off