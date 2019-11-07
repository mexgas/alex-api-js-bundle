CREATE PROCEDURE dbo.ccsp_IVRInsertCallback
@ani varchar(20),
@cam_id smallint
AS
declare @tel varchar(20)
declare @ld varchar(4)
declare @lon tinyint

--declare @result tinyint
select @tel = rtrim(ltrim(@ani))

select @tel = dbo.verifica(@tel)

if left(@tel,1) <> 'E'
begin
	insert into ccoCallsOutSource ( cal_key, cal_telefono, cam_id ) values ( @ani, @tel, @cam_id )
	exec ccsp_RIAOUTInsertNewJOBS_WT_Camp @cam_id, 0
end