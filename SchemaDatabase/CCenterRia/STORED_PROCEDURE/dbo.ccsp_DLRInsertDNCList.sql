CREATE procedure [dbo].[ccsp_DLRInsertDNCList]
@tel varchar(30),
@cam_id as int
as
set nocount on
declare @DNClist as int, @telephone as varchar(30)
select @telephone = dbo.Completa_ListaNegra(@tel)

if left(@telephone,1) = 'E' begin
	select @telephone = @tel
end

if exists(select * from Camplistanegra cl where cl.status = 1 and cl.cam_id = @cam_id)
begin
	select top 1 @DNClist = cl.idtipolista from Camplistanegra  cl where cl.status = 1 and cl.cam_id = @cam_id
	exec ccsp_InsertDNCList @telephone, @DNClist 
	
	insert cchistoriallistanegra 
	values(NULL,@telephone,getdate(),NULL,'8',@DNClist)
end