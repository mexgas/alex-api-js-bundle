CREATE Procedure [dbo].[ccsp_ADMCalifInformation]
@user_id as int,
@type as int
as
if @type = 1
begin
	declare @fecha_ini datetime

	--0 in, 1 out
	select @fecha_ini = convert(datetime,convert(varchar(11),getdate()+' 00:00'))

    --Obtener calificaciones de salida
	(select calif.calif_id AS 'calificationId' ,
    description,
	agt [agentId],
	case when llamadas is null then 0 else llamadas end [calls],
    1 as 'type'
	  from
     (select calif_id, description,agt from cctipocalifout (nolock),ccGenViewRelsSupsAgent where califout_status = 1 AND sup = @user_id) calif
     left join
    (SELECT [user_id], calif_id, COUNT(*) llamadas
	FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_13)), dbo.ccGenViewRelsSupsAgent b
     WHERE cal_inicio >= @fecha_ini
     AND b.sup = @user_id AND statuscall_id = 13 AND calif_id > 0 and user_id = b.agt
	 GROUP BY [user_id], calif_id
	) data
	on (calif.calif_id = data.calif_id AND data.[user_id] = calif.agt))

	union all

    --Obtener calificaciones de entrada
	(select calif.calif_id AS 'calificationId',
    description,
	agt [agentId],
	case when llamadas is null then 0 else llamadas end [calls],
    0 as 'type'
	  from
     (select calif_id, description, agt from cctipocalif (nolock),ccGenViewRelsSupsAgent where calif_status = 1 AND sup = @user_id) calif
     left join
    (SELECT [user_id], calif_id, COUNT(*) llamadas
	FROM cccallsin with (nolock, index(IX_ccCallsIn)), dbo.ccGenViewRelsSupsAgent b WHERE
      cal_inicio >=  @fecha_ini
      and b.sup = @user_id and calif_id > 0 AND user_id = b.agt
	 GROUP BY [user_id], calif_id
	) data
	on (calif.calif_id = data.calif_id AND data.[user_id] = calif.agt))

end

if @type = 2
begin
	select calif_id, description, 0 type from cctipocalif nolock where calif_status = 1
	union all
	select calif_id, description,1 type from cctipocalifout nolock where califout_status = 1
end