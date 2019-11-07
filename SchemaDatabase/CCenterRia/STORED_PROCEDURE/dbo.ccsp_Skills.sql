CREATE PROCEDURE [dbo].[ccsp_Skills]
	@action int ,@userId int=null,@inboundId tinyint=null,@skill int =8,@idwg smallint=null
AS

if @action = 1 begin --lista acd de un admin
	select distinct i.Inbound_id, i.descripcion, g.frame,i.chat mode from ccRIACampEspWG wg
		inner join ccInbound i  ON wg.IdCampEsp=i.Inbound_id
		inner join ccRIAInboundGraph ig ON ig.Inbound_id = i.Inbound_id
		inner join ccRIAGraphics g ON g.graphic_id=ig.graphic_id
		inner join ccRIAWorkGroupUsers wgUser on WgUser.IDWG=wg.IDWG
		where wg.Tipo=0 and wgUser.User_id=@userId
end
else if @action=2 begin
	select distinct A.user_id,A.Nombres+' ' +A.ApellidoPaterno+ ' ' +A.ApellidoMaterno name,isnull(B.Skill,8) skill
		from ccRIACampEspWG D
		inner join ccRIAWorkGroupUsers C on D.IDWG=C.IDWG
		inner join ccusers A on C.User_id=A.User_id
		left join ccSkills B on B.User_id= A.User_id and D.IdCampEsp= B.Inbound_id
		where D.IdCampEsp=@inboundId and A.TipoUser_id=1
end
else if @action =3 begin
	if @userId = 0 begin
		update ccSkills set Skill=@skill where Inbound_id=@inboundId
		select 1,'update All'
	end
	else begin
		if not exists(select * from ccSkills where Inbound_id= @inboundId and User_id=@userId) begin
			insert into ccSkills (Inbound_id,User_id,Skill) values (@inboundId,@userId,@skill)
			select 1,'insert'
			end
		else begin
			update ccSkills set Skill=@skill where Inbound_id=@inboundId and User_id=@userId
			select 1,'update'
		end
	end
end
else if @action = 4 begin --delete wg
	delete s from ccSkills S
inner join (select A.inboundId from
		(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId and B.IDWG= @idwg) A
			left join
		(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId and B.IDWG<> @idwg) B
			on A.inboundId=B.inboundId 	where B.inboundId is null) I
	on I.inboundId = S.Inbound_id where S.User_id=@UserId
end

else if @action = 5 begin --insert wg
	insert into ccSkills(Inbound_id,User_id,Skill)
select A.inboundId,@UserId,8 as Skill from (
(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A
	inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId) A
	left join (select Inbound_id as inboundId from ccSkills C where C.User_id=@UserId) B on A.inboundId=B.Inboundid) where B.inboundId is null

end