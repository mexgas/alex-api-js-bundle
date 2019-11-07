CREATE PROCEDURE xx_Inserta 
@cal_key varchar(20),
@cal_telefono varchar(19),
@cal_telefono2 varchar(19),
@cal_telefono3 varchar(19),
@cal_telefono4 varchar(19),
@cal_telefono5 varchar(19),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@cam_id integer,
@FCallBack smalldatetime = '',
@cal_status tinyint=0,
@User_id integer=0
as
declare @calloutid int
if (@cal_status=0) set @FCallBack=getdate()
Insert into ccoCallsOutSource ( cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id)
values ( @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5, @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id)
select @calloutid=scope_identity()
Insert into xxClienteHistorial ( callout_id , fechaAct ) values ( @calloutid, getdate() )
select @calloutid