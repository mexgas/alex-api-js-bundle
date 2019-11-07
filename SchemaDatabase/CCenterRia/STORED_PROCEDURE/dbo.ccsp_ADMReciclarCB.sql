CREATE PROCEDURE ccsp_ADMReciclarCB
@cam_id smallint,
@tipo smallint=0, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados / 
@calif_id varchar(1000)
as
set nocount on
if @tipo=0
 begin
	update ccoWorkingTable set cal_status = 0 
	where cam_id = @cam_id and cal_status = 1
	return(0)
 end

if @tipo=1
 begin
	update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1
	and callout_id not in (select b.callout_id
	 from ccologdials a left join ccocallsout b on a.callout_id = b.callout_id
	 and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
	 where isnull(calif_id, 0) <> 0)
	return(0)
 end

if @tipo<>2
 return(0)

Set @calif_id = 'update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0, calif_id = 0 
	where cam_id = ' + cast(@cam_id as varchar(10)) + ' and cal_status = 1 and tiporesdial_id = 1 
	and calif_id in (' + case isnull(@calif_id, 0) when 0 then 'calif_id' else @calif_id end + ')'
exec(@calif_id)

return(0)
set nocount off