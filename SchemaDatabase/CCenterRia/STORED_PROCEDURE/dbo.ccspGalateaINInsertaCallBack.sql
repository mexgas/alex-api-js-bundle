CREATE PROCEDURE ccspGalateaINInsertaCallBack
@cal_key varchar(20) ='',
@acd_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0,
@isAuto bit=0
AS
BEGIN
set nocount on
	DECLARE @cam_id SMALLINT
	SELECT @cam_id = isnull(cam_id, 0) FROM  ccinbound WHERE Inbound_id = @acd_id
	exec ccsp_INInsertaCallBack @cal_key, @cam_id, @cal_telefono, @fechadial, @dato1, @dato2, @dato3, @dato4, @dato5, @TelReprograma , @user_id, @isAuto
set nocount off
END