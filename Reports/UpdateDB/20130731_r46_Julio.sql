/*
Autor: Raymundo Gonzalez
Fecha: 2013/07/31
Descripcion: 
	Se modifica el SP ccspGenSession para cambio en reporte
	
Version requerida: 45
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '46'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccspGenSession - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

delete  from ccGenSession with(rowlock)
where login >= @from and login<@to

INSERT INTO ccGenSession ([user_id], extension, login, logout)
select user_id, ext, login, logout
from(select a.user_id, max(Extension) as ext, a.fecha as ''login'',
		(select isnull(max(Fecha),getdate())
			from ccLogLogin b with(nolock)
			where b.user_id = a.user_id and
			b.tipomov = 0 and
			b.fecha >= a.fecha and
			b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
						from ccLogLogin with(nolock)
						where user_id = b.user_id and
						tipomov = 1 and
						fecha > a.fecha)
		) as ''logout''
		from ccLogLogin a
		where a.tipomov=1
		and fecha >= @from
		and fecha <= @to
		group by a.user_id, a.fecha) as sessiontime
order by user_id, login

SELECT TOP 0 * INTO #temp_ccGenSession FROM ccGenSession

INSERT INTO #temp_ccGenSession ([user_id], extension, login, logout)
select user_id, ext, login, logout
from(select a.user_id, max(Extension) as ext, a.fecha as ''logout'',
		(select isnull(max(Fecha),getdate())
			from ccLogLogin b with(nolock)
			where b.user_id = a.user_id and
			b.tipomov = 1 and
			b.fecha <= a.fecha and
			b.fecha >= (select isnull(max(fecha),b.fecha)
						from ccLogLogin with(nolock)
						where user_id = b.user_id and
						tipomov = 0 and
						fecha < a.fecha)
		) as ''login''
		from ccLogLogin a
		where a.tipomov=0
		and fecha >= @from
		and fecha <= @to
		group by a.user_id, a.fecha) as sessiontime
		where datediff(day,login,logout) >= 1
order by user_id, login

UPDATE a with (ROWLOCK)
SET a.logout = b.logout
FROM #temp_ccGenSession b
INNER JOIN ccGenSession a
on a.user_id = b.user_id
and a.login = b.login
and a.logout <> b.logout

DROP TABLE #temp_ccGenSession

return(0)
set nocount off'
 
 	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
