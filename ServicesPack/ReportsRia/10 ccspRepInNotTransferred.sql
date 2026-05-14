USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepInNotTransferred]    Script Date: 28/03/2026 09:51:54 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	--1 as wgId
	--Borrar lo que esta para no repetir
	delete from RepInNotTransferred with(rowlock)
	where date >= @from AND date < @to

	;with ccWgByAcdViewDistinct as(

		select distinct Inbound_id,IDArea,IDWG,descripcion from ccWgByAcdView 
	)

	insert into RepInNotTransferred
	select a.cal_Inicio as [date], a.Inbound_id, 
	b.descripcion as acd, a.statusCall_id, isnull(d.descripcion,'') as statusCall,isnull(d.descripcion,'')  + '_Count' as statusCallCount,1 as [count],  b.IDArea, 
	isnull(Area.AreaName, '') as area, c.IDWG as wgId, isnull(c.WGName,'systemTranslated_WorkGroup') as wg
	,datepart(yyyy,cal_inicio) as [year]
	,datepart(mm,cal_inicio) as [mount]
	,datepart(dd,cal_inicio) as [day]
	,datepart(hh,cal_inicio) as [hour]
	,datepart(mi,cal_inicio) as [minutes]
	,a.cal_id as cal_id,isnull(a.cal_Ani,'') as phone_in
	from cccallsin a 		
	inner join ccWgByAcdViewDistinct b on a.Inbound_id=b.Inbound_id
	left join ccRIACat_WorkGroup c on c.IDWG=b.IDWG
	left join ccstatusllamada d	on a.statusCall_id = d.statusCall_id
	left join ccRIACat_Areas Area on Area.IDArea=b.IDArea
	where cal_inicio >= @from AND cal_inicio < @to and 
	a.statuscall_id in (1,2,3,4,6,7,8)
	and  b.IDArea is not null
end