CREATE PROCEDURE [dbo].[ccsp_RIABlackListLog]
@command tinyint,
@date varchar(22) = null,
@idtipomov int = 0,
@telephone varchar(15) = null,
@Scam_id varchar(1000) = '0',
@GenCSV tinyint,
@endDate varchar(22) = null
AS
set nocount on
declare @sql as nvarchar (4000), @params nvarchar(1000), @newDate nvarchar(22)

If @command=1
 begin
	select idtipomov, movimiento from cctipomovslistanegra
	return(0)
 end

set @params = '@Ndate varchar(22), @Nidtipomov varchar(1),@Ntelephone varchar(20)'

select @sql = case @GenCSV when 1 then 'select ' else 'select top 200 ' end

select @newDate = convert(varchar(8), Cast(@endDate AS smalldatetime), 112)

set @sql = @sql + ' idhistorial, isnull(callout_id,'''') as callout_id, telefono, fecha, isnull(cam_descripcion,'''') as campaña, movimiento, a4.Tipolista 
from cchistoriallistanegra a1 
inner join cctipomovslistanegra a2 on (a1.idtipomov=a2.idtipomov) 
left join cccamps a3 on (a1.cam_id=a3.cam_id)
inner join cctiposlistanegra a4 on (a1.idtipolista = a4.idtipolista) 
where fecha between @Ndate and ' + nchar(39) + @newDate + ' 23:59:59'' '
+ case isnull(@idtipomov, 0) when '0' then '' else ' and a1.idtipomov = @Nidtipomov ' end
+ case isnull(@telephone, 0) when '0' then '' else ' and telefono = @Ntelephone ' end
+ case isnull(@Scam_id, 0) when '0' then '' else ' and a1.cam_id in (' + @Scam_id + ') ' end

execute sp_executesql @sql, @params,@Ndate=@date,@Nidtipomov=@idtipomov,@Ntelephone=@telephone

return(0)

set nocount off