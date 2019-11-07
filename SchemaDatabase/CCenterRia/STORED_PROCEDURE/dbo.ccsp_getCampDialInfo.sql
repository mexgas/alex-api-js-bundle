CREATE procedure [dbo].[ccsp_getCampDialInfo]
@cam_id as integer = 0
AS
declare @idioma as bit
declare @msg as varchar(40)

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

if @idioma = 1
select @msg = 'Last campaigns resume creation'
else
select @msg = 'Ultima generacion de resumen campañas'

if (select count(*) from ccSettings where setting_id = 24) = 0 begin
	insert ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) values (24, convert(varchar(25), dateadd(ss, -10, getdate()), 121), @msg, 1, 'GRL','Detalle','description',0)	
end

if (select datediff(ss, (select valor from ccsettings where setting_id = 24), getdate())) > 60 begin
	update ccsettings set valor = convert(varchar(25), getdate(), 121) where setting_id = 24
	delete ccCampsDialInfo
	insert ccCampsDialInfo
	select c.cam_id, isnull(t.nCalls, 0), isnull(t.nAnswer, 0), isnull(t.nBusy, 0), isnull(t.nNoAnswer, 0),
			 isnull(t.nMachine, 0), isnull(t.nFax, 0), isnull(t.nNoTone, 0), isnull(t.nCongestion, 0), isnull(t.nOthers, 0)
	from ccCamps c left join 
	(
		select cam_id, count(*) as nCalls, 
		count(case tiporesdial_id when 1 then 1 else null end) as nAnswer, 
		count(case tiporesdial_id when 2 then 1 else null end) as nBusy, 
		count(case tiporesdial_id when 3 then 1 else null end) as nNoAnswer, 
		count(case tiporesdial_id when 11 then 1 else null end) as nMachine, 
		count(case tiporesdial_id when 4 then 1 else null end) as nFax, 
		count(case tiporesdial_id when 5 then 1 else null end) as nNoTone,
		count(case tiporesdial_id when 12 then 1 else null end) as nCongestion, 
		count(case when tiporesdial_id not in (1, 2, 3, 4, 5, 11, 12) then 1 else null end) as nOthers 
		from ccoLogDials where fecha > convert(varchar(11), getdate(), 101) 
		group by cam_id
	) t on c.cam_id = t.cam_id
end

select * from ccCampsDialInfo where (cam_id = @cam_id or @cam_id = 0)