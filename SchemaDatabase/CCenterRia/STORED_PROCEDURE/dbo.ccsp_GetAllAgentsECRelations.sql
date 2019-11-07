CREATE PROCEDURE [dbo].[ccsp_GetAllAgentsECRelations]
@User_id varchar(max)
AS
set nocount on

DECLARE @userTable TABLE (Id int,userId int)
DECLARE @userIn TABLE (userId int)

insert into @userTable select * from dbo.fn_RIASplitDelimited(@User_id,'|')

insert into @userIn
select distinct A.user_id
	from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
	inner join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
	inner join @userTable B on A.User_id = B.userId
	Where A.status > 0


select
	case when CA.user_id is null and uIn.userId is null then 0
	when CA.user_id is null and uIn.userId is not null then 1
	when CA.user_id is not null and uIn.userId is null then 2
	else 3 end tipo,
	isnull(C.cam_id,0) as cam_id, B.user_id, isnull(prioridad,0) prioridad, isnull(skill,0) skill, isnull(C.cli_id,0) cli_id
	from @userTable A
	inner join ccUsers B  on A.userId = B.user_id and B.TipoUser_id =1
	left join ccCampsAgente CA on A.userId = CA.user_id
	left join ccCamps C  on C.cam_id = CA.cam_id
	left join @userIn uIn on uIn.userId = B.user_id
	Where B.status > 0
	order by B.user_id