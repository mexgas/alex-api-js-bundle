CREATE PROCEDURE [dbo].[ccsp_Logger]
				@Action smallint,
				@Action_id int = 1,
				@Template_id int,
				@User_id int= 1

			AS
			set nocount on;

			if @Action=1 --Select Logger Table per Template
				begin
					select top 15 login,Upper(left(nombres,1)+left(apellidopaterno,1)) as[initials], c.Description
					from ccenterria..ccUsers a
				 	inner join cw_centerscript..logger b
					on a.User_id = b.User_id
					inner join CW_CenterScript..Logs c
					on b.Action_id = c.Action_id
					where b.Template_id =@Template_id
					group by Login, c.Description, a.Nombres, a.ApellidoPaterno, b.date
					order by b.date asc
				end
			else
			if(@Action=2) --Insert Templatesn Logger Table
				begin					
					insert into Logger (Template_id, User_id, Action_id, date) 
					values (@Template_id,@User_id,@Action_id, GETDATE())
				end