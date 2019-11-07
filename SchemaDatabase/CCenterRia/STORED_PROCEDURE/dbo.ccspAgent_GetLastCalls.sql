CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

declare @lastCallAgt table(
id int not null,
tipo varchar(10) not null,
Hora varchar(10) not null,
Telefono varchar(55) not null,
EspCamp varchar(55) not null,
Calificacion varchar(60),
Duracion varchar(10) not null,
CallBack varchar(60),
cal_key varchar(20),
IDCampEsp smallint not null,
prefijo varchar(maX) null,
GraphicID int 
)
insert into @lastCallAgt
select top 10 c.cal_id as id, 'IN' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '') as Calificacion, 
convert(varchar(14), dateadd(second, 
cal_tDialog - cal_tMoh 
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
,0), 108) Duracion,
'' as CallBack, cal_key, c.inbound_id as IDCampEsp,ISNULL(ccInbound.prefijo,'') Prefijo,
graph.graphic_id GraphicID
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
join ccRIAInboundGraph graph on graph.Inbound_id = c.Inbound_id
inner join ccInbound on ccInbound.Inbound_id=c.Inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
left join 
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer  from ccLogTransfers where tipo=1  group by cal_id,tipo ) as t  
 on c.cal_id=t.cal_id 
where user_id = @user_id and cal_inicio > dateadd(hh, -3, getdate())
order by c.cal_inicio desc


insert into @lastCallAgt
select top 10 c.cal_id as id, 'OUT' as Tipo,convert(varchar(10), cal_inicio, 108) as Hora,cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '') as Calificacion, 
 CONVERT(varchar(8), DATEADD(ss, 
    cal_tDialog - cal_tMoh 
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
    , 0), 114)  as Duracion,
    isnull(convert(varchar(16), cal_fcallback, 121) ,'') as CallBack, cal_key, c.cam_id as IDCampEsp , ISNULL(ccCamps.prefijo,'') Prefijo,
	graph.graphic_id GraphicID
from ccoCallsOut c
inner join ccCamps on ccCamps.cam_id=c.cam_id
left join ccRIACampsGraph graph on graph.cam_id = c.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
left join  
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo) as t  
on c.cal_id=t.cal_id 

where user_id = @user_id and cal_inicio > dateadd(hh, -3, getdate())
order by c.cal_inicio desc

select * from @lastCallAgt
order by hora desc

set nocount off