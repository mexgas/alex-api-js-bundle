CREATE PROCEDURE ccsp_cwInfo
@foo int = 0
AS
declare @MaxFecha datetime
declare @cam_descripcion varchar(50)
declare @TotalCalls int
declare @Contacts int
declare @Camps int
declare @inCalls int
Select @MaxFecha = max(fecha) from ccoLogDials where tiporesdial_id = 1


select @cam_descripcion = cam_descripcion
from ccoLogDials d
inner join ccCamps c on d.cam_id = c.cam_id
where fecha = @MaxFecha

select @TotalCalls = count(*) from ccoLogDials where fecha > dateadd(hh, -1, getdate())
select @Contacts = count(*) from ccoLogDials where fecha > dateadd(hh, -1, getdate()) and tiporesdial_id = 1
select @Camps = count(*) from ccCamps where cam_procesando = 1
select @inCalls = count(*) from ccCallsIn where cal_inicio > dateadd(hh, -1, getdate()) and statuscall_id = 13

select @MaxFecha MaxFecha, @cam_Descripcion cam_descripcion, @TotalCalls TotalCalls, @Contacts Contacts, @Camps Camps, @InCalls InCalls