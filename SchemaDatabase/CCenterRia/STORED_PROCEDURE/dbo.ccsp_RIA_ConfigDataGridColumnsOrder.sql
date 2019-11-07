CREATE procedure [dbo].[ccsp_RIA_ConfigDataGridColumnsOrder]
@option int,
@user_id int,
@idGrid int,
@columnsOrder varchar(1000)
as
set nocount on

if @option = 1
	begin
		select columnsOrder
		from ccDataGridByUser
		where user_id = @user_id 
		and idGrid = @idGrid
	end

if @option = 2
	begin
		if exists (select * from ccDataGridByUser where user_id = @user_id and idGrid = @idGrid)
			begin
				update ccDataGridByUser
				set columnsOrder = @columnsOrder
				where user_id = @user_id
				and idGrid = @idGrid
			end
		else
			insert into ccDataGridByUser
			values (@user_id,@idGrid,@columnsOrder)
	end

set nocount off