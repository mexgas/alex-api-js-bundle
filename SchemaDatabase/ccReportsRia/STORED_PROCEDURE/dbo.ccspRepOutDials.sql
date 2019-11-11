CREATE PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		declare @total decimal(10,2)
		
		select @total = count(*) from ccologdials as a 
		left join ccTipoResultadoDial as b on (a.tipoResDial_id = b.tipoResDial_id)
		where fecha >= @from and fecha < @to
		and descripcion is not null
		and cal_id is not null
		
		delete from RepOutDials with(rowlock)
		where date >= @from AND date < @to
		
		insert into RepOutDials
		select CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121) as [date],
		a.cam_id as campaignId, c.cam_descripcion as campaign, min(d.idwg) as workgroupId, min(wgname) as workgroup, min(f.idarea) as areaId, min(areaname) as area,
		a.tipoResDial_id, descripcion,
		descripcion + '_Count' as descripcion_count,
		count(*) as count,
		descripcion + '_Avg' as descripcion_avg,
		convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121)) as [minutes]
		from ccologdials as a 
		left join ccTipoResultadoDial as b on (a.tipoResDial_id = b.tipoResDial_id)
		left join ccCamps as c on (a.cam_id = c.cam_id)
		left join ccRIAWorkGroup_Calid as d on (a.cal_id = d.cal_id)
		left join ccRIACat_WorkGroup as e on (d.idwg = e.idwg)
		left join ccRIAAreaWorkGroup as f on (e.idwg = f.idwg)
		left join ccRIACat_Areas as g on (f.idarea = g.idarea)
		where fecha >= @from and fecha < @to
		and descripcion is not null
		and a.cal_id is not null
		and d.tipo = 1
		and f.idarea is not null
		group by CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ ':00',121), 
		a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
	end