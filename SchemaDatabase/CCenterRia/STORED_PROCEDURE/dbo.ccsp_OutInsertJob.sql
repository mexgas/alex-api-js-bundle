CREATE PROCEDURE ccsp_OutInsertJob
@cve_t_cred varchar(4),
@no_cuenta  varchar(12),
@cam_id smallint,
@telempleo varchar(14),
@telgarantia varchar(14),
@teldomant varchar(14)
AS
Insert ccoCallsOutSource ( cal_Key, cam_id, cal_telefono, cal_telefono2, cal_telefono3, cal_status )
	Values ( @cve_t_cred + @no_cuenta, @cam_id, @telempleo, @telgarantia, @teldomant, 0 )