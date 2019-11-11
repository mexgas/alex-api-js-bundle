create procedure dbo.ccsp_RIACalcula_WGPriority
@IDWG varchar(255),
@campEspID varchar(255),
@InOut varchar(255)
as
set nocount on
Declare @Tabla varchar(16), @campo varchar(10), @SQL varchar(4000)
Declare @ccRIAWorkGroupUsers Table (User_id smallint)

select @Tabla = case @InOut when 1 then 'ccCampsAgente' else 'ccInboundAgentes' end,
 @campo = case @InOut when 1 then 'cam_id' else 'inbound_id' end

insert into @ccRIAWorkGroupUsers
select A.User_id from ccRIAWorkGroupUsers A join ccUsers B 
on A.User_id = B.User_id and B.TipoUser_id < 2
join ccRIACampEspWG C on A.IDWG = c.IDWG
where A.IDWG = @IDWG and C.IdCampEsp = @campEspID

set @SQL = '(select distinct w.IDWG, prioridad 
 from ' + @Tabla + ' ce join ccRIACampEspWG w on ce.' + @campo + ' = w.IdCampEsp
 join ccRIAWorkGroupUsers wu on ce.user_id = wu.User_id and w.IDWG = wu.IDWG
 where w.IDWG = ' + @IDWG + ' and ce.' + @campo + ' = ' + @campEspID
 + ' and Tipo = ' + @InOut + ') as x' 
 
set @SQL = 'if exists (select IDWG, count(prioridad) sum_prioridad from ' + @SQL + '
group by IDWG having count(prioridad) = 1) 
update ccRIACampEspWG set priority = (select prioridad from ' + @SQL + ') where IDWG = ' + @IDWG + ' and IdCampEsp = ' + @campEspID + ' and Tipo = ' + @InOut + 
 + nchar(13) +
'if exists (select IDWG, count(prioridad) sum_prioridad from ' + @SQL + '
group by IDWG having count(prioridad) > 1) 
update ccRIACampEspWG set priority = 0 where IDWG = ' + @IDWG + ' and IdCampEsp = ' + @campEspID + ' and Tipo = ' + @InOut

exec(@SQL)
return(0)
set nocount off