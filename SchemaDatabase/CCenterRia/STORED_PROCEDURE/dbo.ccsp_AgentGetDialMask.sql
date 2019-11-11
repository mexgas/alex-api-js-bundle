CREATE PROCEDURE ccsp_AgentGetDialMask
@user_id integer
AS
	declare @mask integer
	declare @donde integer

	select @donde =count(*) from syscolumns where id = object_id('ccusers') and name like 'dialmask'

	if @donde > 0
		select @mask = dialmask from ccusers where user_id=@user_id
	else
		select @mask = valor FROM ccSettings WHERE setting_id=20

	select isnull( @mask,7) -- restring todo por default