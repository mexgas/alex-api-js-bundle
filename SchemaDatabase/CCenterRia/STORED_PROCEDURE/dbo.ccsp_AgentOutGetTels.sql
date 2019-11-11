CREATE PROCEDURE ccsp_AgentOutGetTels
@callout_id int
AS

/*
select 	'Telefono1'+' - ' +cal_telefono, 
	'Telefono2'+' - ' +cal_telefono2,
	'Telefono3'+' - ' +cal_telefono3,
	'Telefono4'+' - ' +cal_telefono4,
	'Telefono5'+' - ' +cal_telefono5 
	from ccoCallsOutSource
where callout_id=@callout_id
*/

declare @sSQL varchar(500)
declare @telefono1 varchar(20)
declare @telefono2 varchar(20)
declare @telefono3 varchar(20)
declare @telefono4 varchar(20)
declare @telefono5 varchar(20)
declare @i tinyint
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

set @i = 1

select @Telefono1=cal_telefono, @Telefono2=cal_telefono2, @Telefono3=cal_telefono3, @Telefono4=cal_telefono4, @Telefono5=cal_telefono5
from ccoCallsOutSource
where callout_id=@callout_id
select @sSql = 'select '
if (@telefono1 is not null and @telefono1 > '') select @ssql = @ssql + ' ''Telefono 1 - ' + @Telefono1 + ''' as Telefono1,'
if (@telefono2 is not null and @telefono2 > '') select @ssql = @ssql + ' ''Telefono 2 - ' + @Telefono2 + ''' as Telefono2,'
if (@telefono3 is not null and @telefono3 > '') select @ssql = @ssql + ' ''Telefono 3 - ' + @Telefono3 + ''' as Telefono3,'
if (@telefono4 is not null and @telefono4 > '') select @ssql = @ssql + ' ''Telefono 4 - ' + @Telefono4 + ''' as Telefono4,'
if (@telefono5 is not null and @telefono5 > '') select @ssql = @ssql + ' ''Telefono 5 - ' + @Telefono5 + ''' as Telefono5,'

select @ssql = @ssql + ' ''Otro'' as Other from ccoCallsOutSource where callout_id = ' + cast(@callout_id as varchar(15))
--select @ssql  

if @idioma = 1
begin
set @ssql = replace(@ssql, 'Telefono', 'Telephone')
set @ssql = replace(@ssql, 'Otro', 'Other')
end

--print(@ssql)
exec(@ssql)