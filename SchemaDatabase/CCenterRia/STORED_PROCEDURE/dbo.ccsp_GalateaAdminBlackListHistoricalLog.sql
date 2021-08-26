CREATE PROCEDURE ccsp_GalateaAdminBlackListHistoricalLog --guiandose del sp ccsp_RIABlackListLog
@date smalldatetime,--start date
@endDate smalldatetime,
@idtipomov int,
@telephone varchar(1000),
@Scam_id varchar(1000),
@GenCSV tinyint

AS
set nocount on
declare @sql as nvarchar (4000), @params nvarchar(1000), @newFinalDate nvarchar(22), @newStartDate nvarchar(22)

set @params = '@Ndate varchar(22), @Nidtipomov varchar(1),@Ntelephone varchar(1000)'

select @sql = case @GenCSV when 1 then 'select ' else 'select top 200 ' end

select @newFinalDate = convert(varchar(8), @endDate, 112)
select @newStartDate = convert(varchar(8), @date, 112)

set @sql = @sql + ' idhistorial, isnull(callout_id,0) as callout_id, telefono, fecha, isnull(cam_descripcion,'''') as campaign, movimiento, a4.Tipolista 
from cchistoriallistanegra a1 
inner join cctipomovslistanegra a2 on (a1.idtipomov=a2.idtipomov) 
left join cccamps a3 on (a1.cam_id=a3.cam_id)
inner join cctiposlistanegra a4 on (a1.idtipolista = a4.idtipolista) 
where fecha between '''+ @newStartDate +' 00:00:01''  and ' + nchar(39) + @newFinalDate + ' 23:59:59'' '
+ case isnull(@idtipomov, 0) when '0' then '' when '1' then ' and a1.idtipomov in (1,7)'-- estas lineas las modifique
else ' and a1.idtipomov = @Nidtipomov ' end--aqui solo le di enter y lo puse en otra linea
+ case isnull(@telephone, 0) when '0' then '' else ' and telefono = @Ntelephone ' end
+ case isnull(@Scam_id, 0) when '0' then '' else ' and a1.cam_id in (' + @Scam_id + ') ' end

execute sp_executesql @sql, @params,@Ndate=@date,@Nidtipomov=@idtipomov,@Ntelephone=@telephone

return(0)