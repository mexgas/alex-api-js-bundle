CREATE PROCEDURE [dbo].[SaveReportTemplates] @userId int, @process int, @parameters varchar(max)
AS
BEGIN
	DECLARE @reportName varchar(255)
	DECLARE @id int
	DECLARE @max int
	DECLARE @idReport int

	select @max = 10

	if exists(select *
			  from ccTemplates
		      where user_Id = @userId)
		begin
			select @id = max(id) + 1
			from ccTemplates
		    where user_Id = @userId
		end
	else
		begin
			select @id = 1
		end

	select @reportName = substring(menu_descrip, charindex('|', menu_descrip) + 1, len(menu_descrip))
	from ccMenus
	where menu_id = @process
	
	if not exists (select * from ccTemplates where user_Id = @userId and reportName = @reportName)
		begin
			if (@id <= @max)
				begin
					update ccTemplates
					set id = id + 1
					where user_Id = @userId

					insert into ccTemplates
					values (1, @userId, replace(@parameters,',','|'), @reportName, getdate())
				end
			else
				begin
					delete ccTemplates
					where user_Id = @userId
					and id = @max

					update ccTemplates
					set id = id + 1
					where user_Id = @userId

					insert into ccTemplates
					values (1, @userId, replace(@parameters,',','|'), @reportName, getdate())
				end
		end
	else
		begin
			select @idReport = id
			from cctemplates
			where user_Id = @userId
			and reportName = @reportName

			update cctemplates
			set id = id + 1
			where id < @idReport

			update cctemplates
			set id = 1, parameters = replace(@parameters,',','|'), date = GETDATE()
			where user_Id = @userId
			and reportName = @reportName
		end

	select 0
END