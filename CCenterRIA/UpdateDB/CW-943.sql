/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Trejo
Date: 2018/03/15
Description:



Database: CCenterRia
Required version: 119.119.124

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 1
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 124
	begin
		begin tran
		begin try

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES Funcion FNccsp_Split -- Version BD 119.122 -- '
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''FNccsp_Split'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        DROP FUNCTION FNccsp_Split;
    end'

	 set @process = 'CW-943 ETIQUETAS EN PORTUGUES Creacion de funcion FNccsp_Split -- Version BD 119.122 -- '
    	set @Sql= 'CREATE FUNCTION [dbo].[FNccsp_Split] 
(@string NVARCHAR(MAX),@delimiter CHAR(1)) 
RETURNS @output TABLE(splitdata NVARCHAR(MAX)) 
BEGIN 
    DECLARE @start INT, @end INT 
    SELECT @start = 1, @end = CHARINDEX(@delimiter, @string) 
    WHILE @start < LEN(@string) + 1 BEGIN 
        IF @end = 0  
            SET @end = LEN(@string) + 1
       
        INSERT INTO @output (splitdata)  
        VALUES(SUBSTRING(@string, @start, @end - @start)) 
        SET @start = @end + 1 
        SET @end = CHARINDEX(@delimiter, @string, @start) 
    END 
    RETURN 
END'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMGetCalifDay -- Version BD 119.122 -- '
    	set @Sql= 'ALTER Procedure [dbo].[ccsp_ADMGetCalifDay]
@Tipo bit, @cam_id int = 0, @user_id int = -1
AS
	declare @Total int
	declare @idioma as bit
	declare @sin as varchar(25)
	declare @otra as varchar(7)
	Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
		if @idioma = 1
		begin
			select @sin = ''No disposition''
			select @otra = ''Others''
		end else if @idioma = 2
		begin
			select @sin = ''Sem classificação''
			select @otra = ''Outras''
		end else
		begin
			select @sin = ''Sin Calificacion''
			select @otra = ''Otras''
	end
	create table #CalifTemp (Calificacion varchar(50),Total int )
		if @user_id = -1 begin
		if @tipo = 1
		if @cam_id = 0
			insert into #CalifTemp
			select case when description is not null then description else @sin  end as Calificacion, count(*)
			from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
			where cal_inicio > convert(varchar(11), getdate(), 101)
			and statuscall_id = 13
			group by description
		else
			insert into #CalifTemp
			select case when description is not null then description else @sin end as Calificacion, count(*)
			from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
			where cal_inicio > convert(varchar(11), getdate(), 101)
			and (cam_id = @cam_id ) and statuscall_id = 13
			group by description
		else
			insert into #CalifTemp
			select case when description is not null then description else @sin end as Calificacion, count(*)
			from ccCallsIn ci left join ccTipoCalif ca on ci.calif_id = ca.calif_id
			where cal_inicio > convert(varchar(11), getdate(), 101)
			and (inbound_id = @cam_id or @cam_id = 0) and statuscall_id = 13
			group by description
	end
		else
		begin
		insert into #CalifTemp
		select case when description is not null then ''IN - '' + description else @sin end as Calificacion, count(*)
		from ccCallsIn ci left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		where cal_inicio > convert(varchar(11), getdate(), 101)
		and user_id = @user_id and statuscall_id = 13
		group by description
		insert into #CalifTemp
		select case when description is not null then ''OUT - '' + description else @sin end as Calificacion, count(*)
		from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		where cal_inicio > convert(varchar(11), getdate(), 101)
		and user_id = @user_id and statuscall_id = 13
		group by description
	end
		select @Total = sum(Total) from #CalifTemp
		select case when total > @total / 100 or calificacion = @sin then calificacion else @otra end as Calificacion,
		sum(Total) as Total
		from #CalifTemp
		group by case when total > @total / 100 or calificacion = @sin then calificacion else @otra end
		order by 2 desc
drop table #CalifTemp'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_RIAADMGetCalifDayForced -- Version BD 119.122 -- '
    	set @Sql= 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint,
@calif_id smallint = null
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(50), 
subCalificacion varchar(50) null,
calif_id smallint null,
Total int ) 
declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))
-- Seleccion de idioma -- 
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 1 then ''Other calls with no disposition'' when 2 then ''Chamadas outro sem classificação'' else ''Llamadas otro sin calificar'' end
from ccsettings where setting_id = 27 -- 0esp
select @nIdiomaSub = case valor when 1 then ''No subdisposition'' when 2 then ''Sem subclassificação'' else ''Sin subcalificación'' end
from ccsettings where setting_id = 27 -- 0 esp
if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
		then case when description is not null 
					then description 
					else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
					end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
end end as Calificacion,
case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
and co.cam_id = @cam_id
group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id
if @type=1 
insert into #CalifTemp 
select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
where ci.cal_inicio > @today
and ci.inbound_id = @cam_id
and statuscall_id = 13 
group by description, cci.inbound_id,ci.califSub_id,ci.calif_id
-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null
if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0
else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign 
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id
if @type=1 
select tipo, cam_id, calificacion,subCalificacion,calif_id ,sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total--,0 as iTotal4Campaign
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	and a.inboundId = @cam_id
	group by inboundId, Description
	union all
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end as Calificacion,
	case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total  --iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end, Cam_id,calif_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id 
if @type=0 
select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
then calificacion 
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
end as Calificacion,subCalificacion, calif_id ,sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaña
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
then calificacion 
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
end, Cam_id,subCalificacion, calif_id, iTotal4Campaign
if @type = 3 begin -----entrada acd''s
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @cam_id
	and statuscall_id = 13 
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end
if @type = 4 begin --salida campañas
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
			then case when description is not null 
						then description 
						else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
						end
	else case when sll.descripcion is not null 
	then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id 
	where co.cal_inicio > @today
	and co.cam_id = @cam_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 
drop table #CalifTemp 
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_RIAADMGetCalifDay -- Version BD 119.122 -- '
    	set @Sql= 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = null
AS
set nocount on
create table #CalifTemp (
id int identity,
tipo integer,
Cam_id varchar(50),
Calificacion varchar(50),
subCalificacion varchar(50) null,
calif_id smallint null,
Total int,
iTotal4Campaign int null)
declare @typeACD smallint --= 0
declare @today datetime
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id
select @nIdioma = case valor when 1 then ''Other calls with no disposition'' when 2 then ''Chamadas outro sem classificação'' else ''Llamadas otro sin calificar'' end,
@nIdiomaSub = case valor when 1 then ''No subdisposition'' when 2 then ''Sem subclassificação'' else ''Sin subcalificación'' end
from ccsettings where setting_id = 27 -- 0 esp
---------------OUT ----------------------------
if @type=0 begin
  insert into #CalifTemp
  select 0 as tipo,co.cam_id as cam_id,
  case when co.statuscall_id = 13
      then case when description is not null
      then description else @nIdioma end
  else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
    else ''cw:'' + @nIdioma
    end end as Calificacion
  ,0 as subCalificaion,
  co.calif_id,count(*) cantidad,0 as iTotal4Campaign
  from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
  left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
  left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
  left join ccCamps ci on ci.cam_id = co.cam_id
  where co.cal_inicio > @today
  group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id
  select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
  case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
  from #CalifTemp
  group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id
end
---------------IN ----------------------------
else if @type = 1 begin
  if @typeACD = 0 begin  --Calls
  insert into #CalifTemp
   select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
		,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
		,count(*) as total,0 as iTotal4Campaign
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		left join ccInbound cci on cci.inbound_id = ci.inbound_id
		left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
		group by description, cci.inbound_id,ci.calif_id
    if (select valor from ccSettings where setting_id = 78) = 0 begin
      update #CalifTemp set iTotal4Campaign = 0
    end
    else begin
	update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
      from (
        select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
      inner join #CalifTemp c on t.cam_id = c.cam_id
    end
  end
  else if @typeACD = 1 begin--Chats
	insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
	select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
		case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		a.disposition as calif_id, count(disposition) as Total
        from ccriachats a
        left join ccTipoCalif b on a.disposition=b.calif_id
      where a.chatDate > @today and
	  a.chatStatus=4 and a.inboundId=@inbound_id
    group by inboundId, [description],disposition
  end
  else if @typeACD = 3 begin ---Mail
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
	select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
	case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
	relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
	from conversation conver
	inner join message mess on mess.conversationId = conver.conversationId
	left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	where mess.date > @today and
	conver.inboundId=@inbound_id and mess.messageStatusId >= 5
	group by conver.inboundId,relmesdis.dispositionId,disp.Description
  end
  else if @typeACD = 4 begin --calif twetter
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
	select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
	case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
	relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
	from conversationTwitter conver
	inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
	left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	where mess.date > @today and
	conver.inboundId=@inbound_id and mess.messageStatusId >= 5
	group by conver.inboundId,relmesdis.dispositionId,disp.Description
  end
  select camtemp.tipo,camtemp.cam_id,
	case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
	camtemp.subcalificacion,camtemp.calif_id,camtemp.total
	from #CalifTemp camtemp
    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
end
-------------------SUBCALIFICACIONES IN-------------------
else if @type = 2 begin
  if @typeACD = 0 begin --Calls
    select @typeACD as tipo,cci.inbound_id as cam_id,  [description] as Calificacion,
	isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
    from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
	left join ccTipoCalif ca on ci.calif_id = ca.calif_id
    left join ccInbound cci on cci.inbound_id = ci.inbound_id
    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
    where ci.cal_inicio > @today
	and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
  end
  else if @typeACD = 1 begin --Chat
    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
		isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
		 from ccriachats a
		 left join ccTipoCalif b on a.disposition=b.calif_id
		 left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
		 where a.chatDate > @today and
		a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
		group by inboundId, [description],ctcs.califSubDesc
  end
  else if @typeACD = 3 begin --Mail
	select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
	isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
	from conversation conver
	inner join message mess on mess.conversationId = conver.conversationId
	left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
	where mess.date > @today and
	mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
	group by conver.inboundId,disp.Description,subDisp.califSubDesc
  end
  else if @typeACD = 4 begin --Twitter
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
	isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
	from conversationTwitter conver
	inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
	left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
	where mess.date > @today and
	mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
	group by conver.inboundId,disp.Description,subDisp.califSubDesc
  end
end
-------------------SUBCALIFICACIONES OUT-------------------
else if @type = 4 begin
  select 0 as tipo,co.cam_id as cam_id,
  case when co.statuscall_id = 13
    then case when description is not null
    then description else @nIdioma end
  else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
  end as Calificacion,
  isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad
  from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
  left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
  left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
  left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
  left join ccCamps ci on ci.cam_id = co.cam_id
  where co.cal_inicio > @today
  and co.cam_id = @inbound_id
  and co.calif_id = @calif_id
  group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end
drop table #CalifTemp
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES Columna DescripcionPT ccSettings-- Version BD 119.122 -- '
    	set @Sql= 'ALTER TABLE [ccSettings] ADD DescripcionPT VARCHAR(150) NULL; 
update ccSettings set DescripcionPT = ''Tempo máximo de transferência (segs)'' where setting_id=1
update ccSettings set DescripcionPT = ''Mensagem TTL'' where setting_id=2
update ccSettings set DescripcionPT = ''Fora de serviço'' where setting_id=3
update ccSettings set DescripcionPT = ''Estado do ccServer'' where setting_id=4
update ccSettings set DescripcionPT = ''Estado do ccActivity'' where setting_id=5
update ccSettings set DescripcionPT = ''Estado do ccOut'' where setting_id=6
update ccSettings set DescripcionPT = ''Localização do ccServer'' where setting_id=7
update ccSettings set DescripcionPT = ''Localização do ccActivity'' where setting_id=8
update ccSettings set DescripcionPT = ''Localização do ccOut'' where setting_id=9
update ccSettings set DescripcionPT = ''Sistema'' where setting_id=10
update ccSettings set DescripcionPT = ''PBX CTI link (0: manual| 1: automático)'' where setting_id=11
update ccSettings set DescripcionPT = ''Limiar do nível de serviço (chamadas atendidas y abandonadas)'' where setting_id=12
update ccSettings set DescripcionPT = ''Tempo mínimo de diálogo'' where setting_id=13
update ccSettings set DescripcionPT = ''Tempo mínimo de toque'' where setting_id=14
update ccSettings set DescripcionPT = ''Enviar dados de chamada ao ccActivity'' where setting_id=15
update ccSettings set DescripcionPT = ''Ultima consulta online dos relátorios '' where setting_id=16
update ccSettings set DescripcionPT = ''Recuperar código de área do sistema'' where setting_id=17
update ccSettings set DescripcionPT = ''Usar mensagens predefinidas'' where setting_id=18
update ccSettings set DescripcionPT = ''Habilitar call blending via LiveConnect'' where setting_id=19
update ccSettings set DescripcionPT = ''Ultima atualização dos registros'' where setting_id=21
update ccSettings set DescripcionPT = ''Copiar dados à base ccReports'' where setting_id=22
update ccSettings set DescripcionPT = ''Última consulta do resumo das campanhas'' where setting_id=24
update ccSettings set DescripcionPT = ''Última atualização do índice de abandono (campanhas)'' where setting_id=25
update ccSettings set DescripcionPT = ''Desligar chamadas IP ao sair do agente'' where setting_id=26
update ccSettings set DescripcionPT = ''Idioma'' where setting_id=27
update ccSettings set DescripcionPT = ''ID do tipo de não disponível predefinido'' where setting_id=28
update ccSettings set DescripcionPT = ''Duração da senha'' where setting_id=29
update ccSettings set DescripcionPT = ''Comprimento da senha'' where setting_id=30
update ccSettings set DescripcionPT = ''Tom de alerta ao transferir as chamadas para um agente'' where setting_id=32
update ccSettings set DescripcionPT = ''Atualizar o painel de controle das campanhas'' where setting_id=33
update ccSettings set DescripcionPT = ''Permitir callbacks para números externos'' where setting_id=34
update ccSettings set DescripcionPT = ''Número máximo de dias para reprogramar as chamadas'' where setting_id=35
update ccSettings set DescripcionPT = ''Transferência manual para um número personalizado'' where setting_id=40
update ccSettings set DescripcionPT = ''Tabela do banco de dados externo para discagem manual (é necessária uma configuração do ODBC )'' where setting_id=41
update ccSettings set DescripcionPT = ''Campo (nome) para identificar a pessoa que será chamada manualmente'' where setting_id=42
update ccSettings set DescripcionPT = ''Campo (telefone) para identificar o número que será discado manualmente'' where setting_id=43
update ccSettings set DescripcionPT = ''Caminho da aplicação Agente'' where setting_id=44
update ccSettings set DescripcionPT = ''Arquivo flash (swf) de ícones de chamadas'' where setting_id=45
update ccSettings set DescripcionPT = ''Arquivo flash (swf) de ícones de campanhas'' where setting_id=46
update ccSettings set DescripcionPT = ''Arquivo flash (swf) de ícones de não disponível'' where setting_id=47
update ccSettings set DescripcionPT = ''Arquivo flash (swf) do agente'' where setting_id=48
update ccSettings set DescripcionPT = ''Arquivo XML de idioma'' where setting_id=49
update ccSettings set DescripcionPT = ''Arquivo XML de erros '' where setting_id=50
update ccSettings set DescripcionPT = ''Arquivo XML de mensagens de aviso'' where setting_id=51
update ccSettings set DescripcionPT = ''Arquivo flash (swf) de pré-carregamento do agente'' where setting_id=52
update ccSettings set DescripcionPT = ''Softphone predefinido da aplicação Agente'' where setting_id=53
update ccSettings set DescripcionPT = ''Dispositivos de reprodução'' where setting_id=54
update ccSettings set DescripcionPT = ''Dispositivos de gravação'' where setting_id=55
update ccSettings set DescripcionPT = ''Caminho da aplicação Administrador'' where setting_id=58
update ccSettings set DescripcionPT = ''Intervalo para reciclar os registros não contatados'' where setting_id=59
update ccSettings set DescripcionPT = ''Reciclar registros em modo SIC por resultado de discagem'' where setting_id=60
update ccSettings set DescripcionPT = ''Número máximo de grupos de trabalho por agente'' where setting_id=63
update ccSettings set DescripcionPT = ''Número máximo de campanhas/grupos ACD por grupo de trabalho'' where setting_id=64
update ccSettings set DescripcionPT = ''Duração mínima das gravações em sistemas integrados'' where setting_id=65
update ccSettings set DescripcionPT = ''Localização do(s) engine(s)'' where setting_id=66
update ccSettings set DescripcionPT = ''Servidor de carregamento de registros'' where setting_id=67
update ccSettings set DescripcionPT = ''Mostrar menu para monitorar as chamadas'' where setting_id=68
update ccSettings set DescripcionPT = ''Diferenciar o género dos agentes'' where setting_id=70
update ccSettings set DescripcionPT = ''Mostrar janela de configuração de posições'' where setting_id=71
update ccSettings set DescripcionPT = ''Usar servidor predefinido para carregar registros'' where setting_id=72
update ccSettings set DescripcionPT = ''Configuraçao do servidor predefinido para carregar registros (servidor, banco de dados, senha, ODBC)'' where setting_id=73
update ccSettings set DescripcionPT = ''Arquivo aspx de serviços de integração '' where setting_id=74
update ccSettings set DescripcionPT = ''Permitir condições personalizadas para carregar registros'' where setting_id=75
update ccSettings set DescripcionPT = ''Transferência assistida'' where setting_id=76
update ccSettings set DescripcionPT = ''Versão do banco de dados'' where setting_id=77
update ccSettings set DescripcionPT = ''Mostrar as classificações selecionadas em menos de 1% das interações como outras'' where setting_id=78
update ccSettings set DescripcionPT = ''Mostrar o botão de resumo da chamada'' where setting_id=79
update ccSettings set DescripcionPT = ''Solicitar senha para reciclar callbacks'' where setting_id=80
update ccSettings set DescripcionPT = ''Habilitar callbacks por hora'' where setting_id=81
update ccSettings set DescripcionPT = ''Mostrar o botão de transferência'' where setting_id=82
update ccSettings set DescripcionPT = ''Introduzir um ramal ao iniciar sessão na aplicação Agente'' where setting_id=83
update ccSettings set DescripcionPT = ''Tempo máximo em diálogo (segs)'' where setting_id=84
update ccSettings set DescripcionPT = ''Tempo máximo em disponível (segs)'' where setting_id=85
update ccSettings set DescripcionPT = ''Parar as campanhas inativas'' where setting_id=86
update ccSettings set DescripcionPT = ''Mostrar tipo de não disponível (1: predefinido|2: todos|3: só supervisor|4: por administrador)'' where setting_id=87
update ccSettings set DescripcionPT = ''Ativar não disponível ao se conectar novamente'' where setting_id=88
update ccSettings set DescripcionPT = ''Reciclar os registros terminados'' where setting_id=89
update ccSettings set DescripcionPT = ''Mostrar o número DNIS na aplicaçao Agente'' where setting_id=90
update ccSettings set DescripcionPT = ''Mostrar o nome da campanha'' where setting_id=91
update ccSettings set DescripcionPT = ''Habilitar o serviço Logger'' where setting_id=92
update ccSettings set DescripcionPT = ''Ligações por campanha (servidor|número de registros|0: automático)'' where setting_id=94
update ccSettings set DescripcionPT = ''Eliminar as áreas e todas as suas atribuições'' where setting_id=95
update ccSettings set DescripcionPT = ''Mostrar o teclado telefônico permanentemente'' where setting_id=96
update ccSettings set DescripcionPT = ''Intervalo para calcular o nivel de serviço (0: por dia|1: cada 10 min) Nota: Se o novo nivel é igual à 0, o nivel antigo não será atualizado.'' where setting_id=97
update ccSettings set DescripcionPT = ''Conexão SMTP/ssl'' where setting_id=98
update ccSettings set DescripcionPT = ''Tempo de notas alargado (0|1|2)'' where setting_id=99
update ccSettings set DescripcionPT = ''Mostrar agentes no painel de controle (0: só conectados|1: todos)'' where setting_id=100
update ccSettings set DescripcionPT = ''Prefixo de discagem geral'' where setting_id=101
update ccSettings set DescripcionPT = ''Prefixo de discagem (para habilitar mais de um, somar os valores: 1: auto|2: manual|3: transferência|4: transbordamento)'' where setting_id=102
update ccSettings set DescripcionPT = ''Habilitar os controles de chamada ao transferir entre agentes'' where setting_id=103
update ccSettings set DescripcionPT = ''País'' where setting_id=104
update ccSettings set DescripcionPT = ''Ligar para um mesmo número várias vezes ao dia'' where setting_id=105
update ccSettings set DescripcionPT = ''Mostrar ID do usuário no painel de controle'' where setting_id=107
update ccSettings set DescripcionPT = ''Comprimento do ramal'' where setting_id=108
update ccSettings set DescripcionPT = ''Tempo de discagem em transferência por transbordamento (segs)'' where setting_id=109
update ccSettings set DescripcionPT = ''Permitir ADM e AGT'' where setting_id=110
update ccSettings set DescripcionPT = ''Permitir chamadas de conferência com vários participantes'' where setting_id=111
update ccSettings set DescripcionPT = ''Validar os horários das campanhas antes de ligar'' where setting_id=112
update ccSettings set DescripcionPT = ''Versão da janela de configuração de grupos de trabalho (0: antiga|1: nova)'' where setting_id=113
update ccSettings set DescripcionPT = ''Validar registros das listas negras'' where setting_id=114
update ccSettings set DescripcionPT = ''Solicitar entrada do usuário no campo nome em chamadas manuais'' where setting_id=115
update ccSettings set DescripcionPT = ''Eliminar os registros depois de: (limite de dias)'' where setting_id=116
update ccSettings set DescripcionPT = ''Transferir chamada para IVR e retomá-la ao final do menu'' where setting_id=117
update ccSettings set DescripcionPT = ''Credenciais de acesso à DNCScrub.com'' where setting_id=118
update ccSettings set DescripcionPT = ''Porta de discagem da aplicação Agente'' where setting_id=119
update ccSettings set DescripcionPT = ''Habilitar as chamadas manuais no estado diálogo'' where setting_id=120
update ccSettings set DescripcionPT = ''URL para os eventos do web service Agente'' where setting_id=121
update ccSettings set DescripcionPT = ''URL para os erros do web service Agente'' where setting_id=122
update ccSettings set DescripcionPT = ''Mostrar mensagem de aviso ao alterar os grupos de trabalho'' where setting_id=123
update ccSettings set DescripcionPT = ''Habilitar ferramentas da aplicação AVRS'' where setting_id=124
update ccSettings set DescripcionPT = ''Habilitar ferramentas da aplicação Reminder'' where setting_id=125
update ccSettings set DescripcionPT = ''Permitir chamadas a cobrar'' where setting_id=126
update ccSettings set DescripcionPT = ''Alterar a fórmula para calcular o nível de serviço'' where setting_id=127
update ccSettings set DescripcionPT = ''Recuperar call key das chamadas manuais nos sistemas integrados'' where setting_id=128
update ccSettings set DescripcionPT = ''URL para iniciar sessão através do sistema integrado Ivinex'' where setting_id=129
update ccSettings set DescripcionPT = ''Softphone predefinido da aplicação Administrador'' where setting_id=130
update ccSettings set DescripcionPT = ''Parâmetros do softphone Mizu'' where setting_id=131
update ccSettings set DescripcionPT = ''Usar criptografia de voz Mizutech'' where setting_id=132
update ccSettings set DescripcionPT = ''Servidor primário de criptografia de voz Mizutech'' where setting_id=133
update ccSettings set DescripcionPT = ''Servidor secundário de criptografia de voz Mizutech'' where setting_id=134
update ccSettings set DescripcionPT = ''Configurar os não disponíveis por campanha e grupo ACD'' where setting_id=135
update ccSettings set DescripcionPT = ''Caminho da aplicação Relatórios (nova versão)'' where setting_id=136
update ccSettings set DescripcionPT = ''Localização do assinante da CCenterRIA na aplicação ReportsRIA (NOMEHOSPEDEIRO|IP) '' where setting_id=137
update ccSettings set DescripcionPT = ''Localização do assinante da CCenterRIA na aplicação AVRS (NOMEHOSPEDEIRO|IP) '' where setting_id=138
update ccSettings set DescripcionPT = ''Caminho dos registros de chat'' where setting_id=139
update ccSettings set DescripcionPT = ''Localização do serviço de chat (atualizada automaticamente ao iniciar o serviço)'' where setting_id=140
update ccSettings set DescripcionPT = ''Limiar do nível de serviço (conversas de chat atendidas y abandonadas)'' where setting_id=141
update ccSettings set DescripcionPT = ''Pausar e continuar a gravação na aplicação Agente'' where setting_id=142
update ccSettings set DescripcionPT = ''Localização do(s) engine(s)'' where setting_id=143
update ccSettings set DescripcionPT = ''Intervalo de tempo para mostrar as dicas de contexto (tooltips)'' where setting_id=144
update ccSettings set DescripcionPT = ''Habilitar os grupos ACD de chat'' where setting_id=145
update ccSettings set DescripcionPT = ''Caminho do banco de dados CCRecorderV2'' where setting_id=146
update ccSettings set DescripcionPT = ''Tipo de discagem'' where setting_id=147
update ccSettings set DescripcionPT = ''Tipo de licenciamiento (versão)'' where setting_id=148
update ccSettings set DescripcionPT = ''Plan de discagem para os Estados Unidos'' where setting_id=149
update ccSettings set DescripcionPT = ''URL para recuperar o arquivo XML de dicas de contexto (tooltips)'' where setting_id=150
update ccSettings set DescripcionPT = ''Versão da aplicação Relatórios (0: nova|1: antiga)'' where setting_id=151
update ccSettings set DescripcionPT = ''Atribuir uma lista negra a todas as campanhas novas por padrão'' where setting_id=152
update ccSettings set DescripcionPT = ''Configuração do serviço BaseX (caminho|hospedeiro|porta|usuário|senha|seg|quantidade)'' where setting_id=153
update ccSettings set DescripcionPT = ''Adicionar o número ANI aos arquivos de correio de voz'' where setting_id=154
update ccSettings set DescripcionPT = ''Habilitar os grupos ACD de e-mail'' where setting_id=155
update ccSettings set DescripcionPT = ''Caminho dos registros de e-mail'' where setting_id=156
update ccSettings set DescripcionPT = ''Localização do serviço de e-mail (atualizada automaticamente ao iniciar o serviço)'' where setting_id=157
update ccSettings set DescripcionPT = ''Enviar a resposta dos eventos do web service Agente (0: URL|1: soquete)'' where setting_id=158
update ccSettings set DescripcionPT = ''Intervalo de dias para copiar os registros do finder à BaseX'' where setting_id=159
update ccSettings set DescripcionPT = ''Integração Asterisk'' where setting_id=160
update ccSettings set DescripcionPT = ''Enviar call key ao transferir para grupo ACD'' where setting_id=161
update ccSettings set DescripcionPT = ''Tom de alerta ao receber uma nova mensagem de chat'' where setting_id=162
update ccSettings set DescripcionPT = ''Mostrar ID da chamada na aplicação Agente'' where setting_id=163
update ccSettings set DescripcionPT = ''Validar as tarifas de chamadas manuais'' where setting_id=164
update ccSettings set DescripcionPT = ''Formato de gravação '' where setting_id=165
update ccSettings set DescripcionPT = ''Restringir as chamadas em comformidade com os horários legais de ligação'' where setting_id=166
update ccSettings set DescripcionPT = ''Localização do serviço Downloader (atualizada automaticamente ao iniciar o serviço)'' where setting_id=167
update ccSettings set DescripcionPT = ''Habilitar aplicação CRM'' where setting_id=168
update ccSettings set DescripcionPT = ''Mostrar novo finder e desativar o antigo (AVRS e chats)'' where setting_id=169
update ccSettings set DescripcionPT = ''Localização da aplicação CRM'' where setting_id=170
update ccSettings set DescripcionPT = ''Validar o formato dos números telefônicos '' where setting_id=171
update ccSettings set DescripcionPT = ''Baixar as seqüências numéricas da COFETEL automaticamente'' where setting_id=172
update ccSettings set DescripcionPT = ''Habilitar os grupos ACD de Twitter'' where setting_id=173
update ccSettings set DescripcionPT = ''URL do web service de conexão à Twitter API'' where setting_id=174
update ccSettings set DescripcionPT = ''Caminho dos registros de Twitter'' where setting_id=175
update ccSettings set DescripcionPT = ''Credenciais de replicação (hospedeiro\usuárioWindows|senhaWindows|usuárioSQL|senhaSQL|hospedeiro)'' where setting_id=176
update ccSettings set DescripcionPT = ''Atribuir o número ANI predefinido a todas as novas campanhas'' where setting_id=177
update ccSettings set DescripcionPT = ''Localização do serviço Twitter (atualizada automaticamente ao iniciar o serviço)'' where setting_id=178
update ccSettings set DescripcionPT = ''Número de tentativas para desativar conta de Twitter'' where setting_id=179
update ccSettings set DescripcionPT = ''Número máximo de grupos de trabalho por campanha e grupo ACD'' where setting_id=180
update ccSettings set DescripcionPT = ''Mostrar uma mensagem de aviso em erro de gravação do engine'' where setting_id=181
update ccSettings set DescripcionPT = ''Formato para reproduzir as gravações'' where setting_id=182
update ccSettings set DescripcionPT = ''Configuração da WebRTC (<type>|<ws[,ws_gw]>|<private_identity>|<public_identity>|<password>|<realm>|<ice_servers>|<IMS>|<WebBreaker>)'' where setting_id=183
update ccSettings set DescripcionPT = ''Enviar pacote para monitorar as portas de saída'' where setting_id=186
update ccSettings set DescripcionPT = ''Audiofrequência de mensagens (0: 6kHz|1: 8 kHz)'' where setting_id=187
update ccSettings set DescripcionPT = ''Intervalo de registros para criar uma nova BaseX'' where setting_id=188
update ccSettings set DescripcionPT = ''Intervalo de segundos para atualizar os contadores'' where setting_id=189
update ccSettings set DescripcionPT = ''Percentagem do total de chamadas por segundo'' where setting_id=190
update ccSettings set DescripcionPT = ''Restringir as transferências aos números de uma mesma área'' where setting_id=191
update ccSettings set DescripcionPT = ''Mostrar as chamadas de entrada em espera na aplicação Agente'' where setting_id=192
update ccSettings set DescripcionPT = ''Mostrar o contador de tempo ao pausar as chamadas'' where setting_id=193
update ccSettings set DescripcionPT = ''Recuperar call key da última chamada preditiva'' where setting_id=194
update ccSettings set DescripcionPT = ''Validar os números locais com código de área (10 dígitos) - México'' where setting_id=195
update ccSettings set DescripcionPT = ''Campanha predeterminada de chamadas manuais'' where setting_id=196
update ccSettings set DescripcionPT = ''Configuração da fila de mensagens'' where setting_id=199
update ccSettings set DescripcionPT = ''Compartilhar os valores da chamada preditiva com a chamada manual em discagem seletiva '' where setting_id=200
update ccSettings set DescripcionPT = ''Parâmetros que serão adicionados no registro Loader (para habilitar mais de um, somar os valores: 1: nenhum|2: funções|3: erros|4: dados internos)'' where setting_id=254
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES Permitir el valor 2 que es portugués en base de datos ccsp_RIAccSettingsConfig -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null
AS
set nocount on
declare @idioma tinyint
declare @activeChat tinyint
select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145
if @command=0
	begin
	SELECT case @idioma when 0 then descripcion 
						when 1 then [description]
						else DescripcionPT end descripcion
	FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
	order by descripcion
	return(0)
	end

if @command=1
	begin
	Select setting_id, case @idioma  
						when 0 then descripcion 
						when 1 then [description]
						else DescripcionPT end descripcion,valor, tipo,validate
	from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'',''SV'')
	and (setting_id not in (139,140,141)
	or   setting_id     in (139,140,141) and @activeChat > 0)
	order by tipo, descripcion
	return(0)
	end

if @command=2
	begin
	if @setting_id = 27 and @value not in(''0'',''1'',''2'') begin
		set @value = 0
	end
	else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'',''14'',''15'',''16'') begin
		set @value = 1
	end
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
	end
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES Muestra menús según el idioma ccsp_MenuViews-- Version BD 119.122 -- '
    	set @Sql= 'alter procedure [dbo].[ccsp_MenuViews]
@superID as int = 0,
@mView_id As smallint = null,
@mode As smallint = null
as
set nocount on
declare @langU as tinyint, @XML as xml
select @langU=valor from ccSettings where setting_id=27
if isnull(@mView_id,0) <= 0
 begin
	SELECT @XML = (
		SELECT * FROM (
			SELECT distinct 1 as TAG, NULL as Parent, [view].menu_id as "view!1!menuId",
				case @langU when 0 then substring(Menu.menu_descrip, 1, charindex(''|'', Menu.menu_descrip)-1)				
							when 1 then substring(Menu.menu_descrip, charindex(''|'', Menu.menu_descrip)+1, len(Menu.menu_descrip))
			   else substring(Menu.menu_descrip, charindex(''|'', Menu.menu_descrip)+2, len(Menu.menu_descrip))
			   end as "view!1!menu_descrip", NULL as "viewMode!2!id", NULL as "viewMode!2!selected"
			FROM ccMenu_Views as [view] 
			join ccMenus as Menu on [view].menu_id = Menu.menu_id and [view].type = Menu.type
			join ccMenuUser Users on [view].menu_id = Users.id_menu and [view].type = Users.type
			where [view].status=1 and id_User = @superID
			UNION ALL
			SELECT distinct 2, 1, [view].menu_id, NULL, viewMode.typeView, case when viewMode.typeView = dbo.fn_viewMode (@superID, [view].menu_id) then 1 else 0 end
			FROM ccMenu_Views as viewMode
			join ccMenu_Views as [view] on viewMode.mView_id = [view].mView_id
			where viewMode.status=1
		) X
		ORDER BY "view!1!menuId", tag
		FOR XML EXPLICIT, TYPE
	)
	select @XML
	--select isnull(cast(@XML as varchar(max)),'''')
	return(0)
 end

declare @mView_idNew smallint, @mView_idDel smallint, @menu_Log varchar(100), @language tinyint
select @language=valor from ccSettings where setting_id = 27
select @mView_idNew=mView_id from ccMenu_Views where menu_id = @mView_id and typeView = @mode
select @menu_Log=case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1) 
when 1 then substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip))
else substring(menu_descrip, charindex(''|'',menu_descrip)+2, len(menu_descrip)) end
from ccMenus where menu_id=@mView_id

if not exists (select User_id from ccMenu_ViewsUser where User_id=@superID and mView_id=@mView_idNew)
 begin
	select @mView_idDel = a.mView_id FROM ccMenu_Views a join ccMenu_ViewsUser b on a.mView_id = b.mView_id where b.User_id = @superID and a.menu_id = @mView_id
	delete ccMenu_ViewsUser where User_id=@superID and mView_id = @mView_idDel
	insert into ccMenu_ViewsUser select @superID, @mView_idNew
 end

select isnull(@mView_idNew, -1), @menu_Log menu
return(0)
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES TABLE ccRIACat_AdminRole -- Version BD 119.122 -- '
    	set @Sql= 'ALTER TABLE ccRIACat_AdminRole ALTER COLUMN Description [varchar](100);
update ccRIACat_AdminRole set Description = ''Personalizado|Custom|Personalizado'' where Role_id=1
update ccRIACat_AdminRole set Description = ''Administrador general|General administrator|Administrador geral'' where Role_id=2
update ccRIACat_AdminRole set Description = ''Supervisor|Supervisor|Supervisor'' where Role_id=3
update ccRIACat_AdminRole set Description = ''Administrador de áreas|Areas administrator|Administrador das áreas'' where Role_id=4
update ccRIACat_AdminRole set Description = ''Administrador de sistemas|IT administrator|Administrador do sistema'' where Role_id=5
update ccRIACat_AdminRole set Description = ''Gerente|Manager|Gerente'' where Role_id=6
update ccRIACat_AdminRole set Description = ''Campañas|Campaigns|Campanhas'' where Role_id=7
update ccRIACat_AdminRole set Description = ''Grupos ACD|ACD Groups|Grupos ACD'' where Role_id=8
update ccRIACat_AdminRole set Description = ''Ambos|Both|Ambos'' where Role_id=9
update ccRIACat_AdminRole set Description = ''Personalizado|Custom|Personalizado'' where Role_id=10
update ccRIACat_AdminRole set Description = ''Campañas|Campaigns|Campanhas'' where Role_id=11
update ccRIACat_AdminRole set Description = ''Grupos ACD|ACD Groups|Grupos ACD'' where Role_id=12
update ccRIACat_AdminRole set Description = ''Ambos|Both|Ambos'' where Role_id=13
update ccRIACat_AdminRole set Description = ''Personalizado|Custom|Personalizado'' where Role_id=14
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_RiaMenuByRole -- Version BD 119.122 -- '
    	set @Sql= 'ALTER procedure [dbo].[ccsp_RiaMenuByRole]
@Type tinyint,
@role_id smallint = null,
@Menu_id smallint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on
select @AE = valor from ccsettings where setting_id = 71
Declare @NRS tinyint
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
If @Type = 1 -- Get language
begin
	select valor from ccSettings where setting_id = 27
	return(0)
end
If @Type = 2 -- Carga todos los roles
begin
	select Role_id, Description from ccRIACat_AdminRole where type = 1 and Role_id<>1 order by priority
	return(0)
end

If @Type = 3 -- Carga roles
begin
select rm.role_id, m.menu_descrip, rm.id_menu,rm.type,m.release from dbo.ccRIARoleMenu rm, ccmenus m where rm.id_menu = m.menu_id and rm.role_id = @role_id and rm.type = 1 and
	((rm.id_Menu not in (41,42,53)) or (rm.id_Menu = 41 and @CM = 1) or (rm.id_Menu = 42 and @ae > 0) or (rm.id_Menu = 53 and @NRS = 1))
	return(0)
end

declare @language tinyint
select @language=valor from ccSettings where setting_id = 27
If @Type = 4 -- Inserta rol
begin
if not exists(select role_id from ccRIARoleMenu where role_id = @role_id and id_Menu = @Menu_id and type = 1)
begin
	Insert into ccRIARoleMenu (role_id, id_Menu, type) values(@role_id, @Menu_id, 1)
	select
		(select case @language when 0 then substring(Description, 1, charindex(''|'',Description)-1)
		when 1 then substring(Description, charindex(''|'',Description)+1, len(Description))
		else substring(Description, charindex(''|'',Description)+2, len(Description)) end
		from ccRIACat_AdminRole where role_id=@role_id) as sRole,
		(select case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1)
		when 1 then substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip))
		else substring(menu_descrip, charindex(''|'',menu_descrip)+2, len(menu_descrip)) end
		from ccMenus where menu_id=@Menu_id) as sMenu
	return(0)
end
end

If @Type = 5 -- Elimina rolf
begin
delete from ccRIARoleMenu where role_id =@role_id  and id_Menu=@Menu_id and type= 1
select
	(select case @language when 0 then substring(Description, 1, charindex(''|'',Description)-1)
	when 1 then substring(Description, charindex(''|'',Description)+1, len(Description))
	else substring(Description, charindex(''|'',Description)+2, len(Description)) end
	from ccRIACat_AdminRole where role_id=@role_id) as sRole,
	(select case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1)
	when 1 then substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip))
	else substring(menu_descrip, charindex(''|'',menu_descrip)+2, len(menu_descrip)) end
	from ccMenus where menu_id=@Menu_id) as sMenu
return(0)
end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES Permisos de Administrador ccspRIA_AdminPermissions-- Version BD 119.122 -- '
    	set @Sql= 'Alter procedure [dbo].[ccspRIA_AdminPermissions]
@Type tinyint,	-- 1:Catalogo/2:Supervisores/3:permisos_X_supervisor/4:actualiza_supervisor/5:actualiza_todo
@user_id smallint = null,
@per_id tinyint = null,
@value bit=1
as
set nocount on
if @Type = 1
	begin
	declare @Idioma INT
	select @Idioma = valor from ccsettings where setting_id = 27
	select CatAdmin.per_id, case @Idioma 
	  when 0 then substring(CatAdmin.per_desc, 1, charindex(''|'',CatAdmin.per_desc)-1)
	  when 1 then substring(CatAdmin.per_desc, charindex(''|'',CatAdmin.per_desc)+1, charindex(''|'',CatAdmin.per_desc,charindex(''|'', CatAdmin.per_desc)+1)-charindex(''|'', CatAdmin.per_desc)-1)
	  when 2 then (SELECT item  FROM dbo.SplitString((select permissions.per_desc from ccRIACat_AdminPermissions as permissions where permissions.per_id= CatAdmin.per_id), ''|'')  where id=3)
	end per_desc,release
	from ccRIACat_AdminPermissions as CatAdmin where CatAdmin.bStatus = 1
	return(0)
	end

if @Type = 2
	begin
	select User_id, Login, Nombres +
	replace(''''+isnull(ApellidoPaterno, '''') + ''''+isnull(ApellidoMaterno, ''''), '''', '''') Nombre
	from ccUsers where tipouser_id in (2,6)
	order by Login
	return(0)
	end

if @Type = 3
	begin
	if not exists(select user_id from ccUsers where TipoUser_id in(2,6) and user_id = @user_id)
		return(0)
	select c.per_id, cast(cast(isnull(u.user_id, 0) as bit) as tinyint) value
	from ccRIACat_AdminPermissions c
		left join ccRIAUsr_AdminPermissions u
		on c.per_id = u.per_id and u.user_id = @user_id
	where c.bStatus = 1
		order by c.per_id
	return(0)
	end

if @Type = 4
	begin
	if cast(@User_id as bit) <> 1 or cast(@per_id as bit) <> 1
	return(0)
	if @value=0
		delete ccRIAUsr_AdminPermissions where user_id = @user_id and per_id = @per_id
	else if not exists (select user_id from ccRIAUsr_AdminPermissions where user_id = @user_id and per_id = @per_id)
		insert ccRIAUsr_AdminPermissions select @user_id, @per_id
	return(0)
	end

if @Type = 5
	begin
	if not exists(select per_id from ccRIACat_AdminPermissions)
		return(0)
	if @value=0
		delete ccRIAUsr_AdminPermissions where per_id = @per_id
	else
		insert into ccRIAUsr_AdminPermissions select User_id , per_id
		from ccUsers cross join ccRIACat_AdminPermissions
		where tipouser_id in (2,6) and per_id in (@per_id)
		and cast(User_id as varchar(10)) + ''|'' + cast(per_id as varchar(10))
		not in (select cast(User_id as varchar(10)) + ''|'' + cast(per_id as varchar(10))
		from ccRIAUsr_AdminPermissions)
		order by 1,2
	return(0)
	end
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES TABLE ccoXferType -- Version BD 119.122 -- '
    	set @Sql= 'ALTER TABLE ccoXferType
ALTER COLUMN description varchar(100)
update ccoXferType set description = ''Transferencia a número interno|Transfer to Internal numbers|Transferência para número interno'' where XferType_id=1
update ccoXferType set description = ''Transferencia a número externo|Transfer to External numbers|Transferência para número externo'' where XferType_id=2
update ccoXferType set description = ''Ambas|Both|Ambas'' where XferType_id=3
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_RIACATMenu -- Version BD 119.122 -- '
    	set @Sql= 'alter procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint
set @MenuMail=0
set @MenuCRM = 0
set @monitorPortMenu =0
select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor=''1'' then 1 else 0 end from ccsettings where setting_id = 186

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,83,84,85,69))
		or (menu_id = 41 and @CM = 1)
		or (menu_id = 42 and @AE > 0)
		or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		or (menu_id = 69 and @monitorPortMenu > 0)--Monitoreo de puertos
		)
		order by ordengral asc
		return(0)
	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc
		return(0)
	end

	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end
end

if @Type=2
begin
	delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
	return(0)
end

if @Type=3
begin
	insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
	return(0)
end

if @Type=4
begin
	declare @lan varchar(3), @page varchar(200)
	select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
	select @lan = case valor when 0 then ''ES'' 
							 when 1 then ''EN''
							 else ''PT'' end from ccSettings where setting_id = 27
	select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
	return(0)
end
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMAddAgent-- Version BD 119.122 -- '
    	set @Sql= 'Alter PROCEDURE ccsp_ADMAddAgent
@Login varchar(12),
@Nombres varchar(45),
@ApellidoPaterno varchar(35),
@ApellidoMaterno varchar(35),
@Password  varchar(15),
@Sexo bit
AS
set nocount on
declare @User_id smallint
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
if exists(select login from ccUsers where Login = @Login and status > 0)
 begin
	select -1, case @idioma when 1 then ''Login in Use'' 
							when 2 then ''Login em Uso''
							else ''Login en Uso'' end
	return(0)
 end

if exists( select Nombres from ccUsers where Nombres=@Nombres AND ApellidoPaterno=@ApellidoPaterno AND ApellidoMaterno=@ApellidoMaterno)
 begin
	select -2, case @idioma when 1 then ''Name in Use'' 
							when 2 then ''nome em uso''
							else ''Nombre en Uso'' end
	return(0)
 end

Insert ccUsers ( Login, Nombres, ApellidoPaterno, ApellidoMaterno, Password, TipoUser_id, Status, TipoLLamadas, Sexo )
 Values( @Login, @Nombres, @ApellidoPaterno, @ApellidoMaterno, @Password, 1, 1, 1, @Sexo )
select @User_id= User_id from ccUsers where Login= @Login
select @User_id, case @idioma when 1 then ''User '' + @Login + '' Added Succesfully''
when 2 then ''usuário '' + @Login + '' Descarregado''
else ''Usuario '' + @Login + '' Dado de Alta'' end
return(0)
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMCamp -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_ADMCamp]
		@Descripcion varchar(40),
		@cam_id smallint,
		@cli_id smallint=1,
		@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 2=Eliminar
		@ventana tinyint = 2, -- 0 Falso, 1 Verdadero, 2 Sin Cambio
		@timer int = 2,
		@Activa tinyint = 2,
		@user_id int=0
		AS
		set nocount on
		--ccsp_ADMCamp ''ABCD'', 1, 0, 2, 1 , 1 , 1
		declare @new_cam_id smallint
		declare @idioma as bit
		Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
		--HLAS no crear campa±as sin cliente asignado 20050104
		if not exists(select cli_id from ccClientes where cli_id = @cli_id)
			return(0)
		select @cli_id = max(cli_id) from ccClientes
		if isnull(@cli_id,0)=0 
		 begin
			select 0, case @idioma when 1 then ''Please check Clients Catalogue and make sure there is at least one client''
			when 2 then ''Verificar se existe pelo menos um cliente no catálogo de clientes''
			else ''Favor de revisar el Catálogo de Clientes y verificar que exista alguno'' end
			return(0)
		 end 

		if @Tipo in(1,4)
		begin
			if exists (select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
			 begin
				select 0, case @idioma when 1 then ''Name in Use'' 
										when 2 then ''O nome está em uso''
										else ''Nombre en Uso'' end
				return(0)
			 end

			Insert ccCamps (cam_descripcion, cli_id, cam_ShowCalifWnd, cam_StartTimerOnHangUp)
			 Values(@Descripcion, @cli_id, @ventana, @timer)
			select @new_cam_id = SCOPE_IDENTITY()
			if @new_cam_id is null and @Tipo=4
			 begin
				select 0, case @idioma when 1 then ''Error creating campaign'' 
											when 1 then ''Não foi possível salvar a campanha'' 
											else ''Error al crear campaña'' end
				return(0)
			 end

			insert into ccoDialerCamp (dialer_id, cam_id)
			 select dialer_id, @new_cam_id as cam_id from ccoDialers where status=1
			insert into ccCalifCamp (calif_id, cam_id, tipo)
			 select calif_id, @new_cam_id as cam_id, 1 as tipo from ccTipoCalifOUT
			if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_cam_id, 1, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
			 end

			else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_cam_id, 1, 0
			 end

			select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Added Succesfully''
			when 2 then ''Campanha: '' + upper(@Descripcion) + '' Salva com êxito''
			else ''Campaña: '' + upper(@Descripcion) + '' Dada de Alta'' end
			return(0)
		 end

		if @Tipo=2
		 begin
			Update ccCamps set cam_descripcion= @Descripcion where cam_id = @cam_id
			if @ventana <> 2 Update ccCamps set cam_ShowCalifWnd=@ventana where cam_id = @cam_id
			if @timer <> 2 	Update ccCamps set cam_StartTimerOnHangUp=@timer where cam_id = @cam_id
			if @Activa <> 2 Update ccCamps set cam_activo=@Activa where cam_id = @cam_id
			select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Modified''
			when 2 then ''Campanha: '' + upper(@Descripcion) + '' Editada''
			else ''Campaña: '' + upper(@Descripcion) + '' Modificada'' end
			return(0)
		 end

		if @Tipo=3
		 begin
		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id
 is null and A.cam_id = @cam_id
			delete from ccCampsAgente where cam_id = @cam_id
			delete from ccoDialerCamp where cam_id = @cam_id
			delete from ccoWorkingTable where cam_id = @cam_id
			delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
			delete from ccoLogDials where cam_id = @cam_id
			delete from ccoCallsOut where cam_id = @cam_id
			delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
			delete from ccoCallsOutSource where cam_id = @cam_id
			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCamBackup B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and 
A.cam_id = @cam_id and A.tipo = 1
			Delete ccSupervisorCam where cam_id  = @cam_id and tipo = 1
			if exists(select cam_id from ccCampsAgente where cam_id = @cam_id)
			 begin
				select 0, case @idioma when 1 then ''There are Agents Related to this Campaign''
				when 2 then ''Tem agentes atribuídos à esta campanha''
				else ''Existen Agentes Relacionados con esta Campaña'' end
				return(0)
			 end

			if exists(select cam_id from ccoCallsOut where cam_id = @cam_id)
			 begin
				select 0, case @idioma when 1 then ''There are Call Registries Related with this Campaign''
				when 2 then ''Tem registros de chamadas ligados à esta campanha''
				else ''Existen Registros de Llamadas Relacionados con esta Campaña'' end
				return(0)
			 end

			insert ccCampsMovs (cam_id, TipoMov, NewRecords,  CBRecords, user_id) 
			 Values(@cam_id, 5, 0,0,@user_id)
			Delete ccCamps Where cam_id = @cam_id
			select -1, case @idioma when 1 then ''Campaign: '' + upper(@Descripcion) + '' Deleted''
			when 2 then ''Campanha: '' + upper(@Descripcion) + '' eliminada com êxito''
			else ''Campaña: '' + upper(@Descripcion) + '' Eliminada'' end
			return(0)
		 end
		set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMCampDialers -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMCampDialers
@cam_id smallint,
@dialer_id smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40)
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	select @Descripcion=Upper(Descripcion) from ccoDialers where dialer_id=@dialer_id
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccoDialerCamp where cam_id = @cam_id and dialer_id=@dialer_id
		) > 0	
			if @idioma = 1
			select 0, ''Dialer Already Assigned''
			else if @idioma = 2
			select 0, ''Dialer já atribuída''
			else
			select 0, ''Dialer ya Asignado''
		else
		begin
			Insert ccoDialerCamp ( dialer_id, cam_id  ) Values ( @dialer_id, @cam_id)
			if @idioma = 1
			select -1, ''Dialer: '' + @Descripcion + '' Assigned to the Campaign OK''
			else if @idioma = 2
			select -1, ''Dialer: '' + @Descripcion + '' Atribuída com êxito''
			else
			select -1, ''Dialer: '' + @Descripcion + '' Asignado en la Campaña OK''
		end
	end
	if ( @Tipo=3 )
	begin
		Delete ccoDialerCamp where cam_id = @cam_id and dialer_id=@dialer_id
		if @idioma = 1
		select -1, ''Dialer: '' + @Descripcion + '' Removed from Campaign''
		else if @idioma = 2
		select -1, ''Dialer: '' + @Descripcion + '' Eliminada com êxito''
		else
		select -1, ''Dialer: '' + @Descripcion + '' Removido de la Campaña''
	end
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMCampHorarios -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_ADMCampHorarios]
@cam_id smallint,
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40),@valueShudulerLey varchar(max)
declare @idioma bit,@authorizationCallLaw bit,@msgLaw varchar(max)
declare @isShudulerLey bit,@shourStart varchar(max),@shourEnd varchar(max)
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
select @Descripcion=Upper(Descripcion) from ccHorarios where horario_id=@horario_id
if @Tipo=1 begin
	if ( select count(*) from ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id) > 0
		if @idioma = 1
		select 0, ''Schedule Already Assigned''
		else if @idioma = 2
		select 0, ''Horário já atribuído''
		else
		select 0, ''Horario ya Asignado''
	else
	begin
		select @valueShudulerLey = valor from ccsettings where setting_id=166
		select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
		if @valueShudulerLey='''' begin
			set @valueShudulerLey=''0|07:00|22:00''
			update ccsettings set valor=@valueShudulerLey where setting_id=166
		end

		if @isShudulerLey = 1 begin
			select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
		end

		else begin
			select @shourStart=''07:00'',@shourEnd=''22:00''
		end
		if @isShudulerLey = 0 begin
			set @msgLaw= case when @idioma = 1 then ''You can call 24 hours'' when @idioma = 2 then ''É possível chamar as 24 horas do dia'' else ''Se podra llamar las 24 horas'' end
		end

		else begin
			set @msgLaw= case when @idioma = 1 then ''Only you can call on schedule ''+ @shourStart + '' to '' + @shourEnd
				when @idioma = 2 then ''É possível chamar entre as ''+ @shourStart + '' e as '' + @shourEnd
				else ''Solo se podra llamar en el horario ''+ @shourStart + '' a '' + @shourEnd end
		end

		Insert ccCampsHorarios (cam_id, Horario_id  ) Values ( @cam_id, @horario_id )
		if @idioma = 1
		select -1, ''Schedule: '' + @Descripcion + '' Assigned to the Campaign OK\n''+@msgLaw
		else if @idioma = 2
		select -1, ''Horário: '' + @Descripcion + '' Atribuído com êxito\n''+@msgLaw
		else
		select -1, ''Horario: '' + @Descripcion + '' Asignado en la Campaña OK\n''+@msgLaw
	end
end

if ( @Tipo=3 )
begin
	Delete ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id
	if @idioma = 1
	select -1, ''Schedule: '' + @Descripcion + '' Removed from Campaign''
	else if @idioma = 2
	select -1, ''Horário: '' + @Descripcion + '' Eliminada com êxito''
	else
	select -1, ''Horario: '' + @Descripcion + '' Removido de la Campaña''
end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMClient -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMClient
@Descripcion varchar(40),
@cli_id smallint,
@Tipo tinyint
AS
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccClientes where cli_nombre = @Descripcion
		) > 0
			if @idioma = 1
			select 0, ''The client already exists''
			else if @idioma = 2
			select 0, ''O cliente já existe''
			else
			select 0, ''El cliente ya existe''
		else
		begin
			Insert ccClientes ( cli_nombre )  Values( @Descripcion )
			if @idioma = 1		
			select -1, ''Client: '' + @Descripcion + '' added succesfully''
			else if @idioma = 2		
			select -1, ''Cliente: '' + @Descripcion + '' salvo com êxito''
			else
			select -1, ''Cliente: '' + @Descripcion + '' dado de alta''
		end
	end

	if ( @Tipo=2 )
	begin
		Update ccClientes set cli_nombre= @Descripcion where cli_id = @cli_id
		if @idioma = 1
		select -1, ''Client: '' + @Descripcion + '' updated''
		if @idioma = 2
		select -1, ''Cliente: '' + @Descripcion + '' editado com êxito''
		else
		select -1, ''Cliente: '' + @Descripcion + '' modificado''
	end

	if ( @Tipo=3 )
	begin
		if ( select count(*) from ccInbound where cli_id = @cli_id
		) > 0
			if @idioma = 1
			select 0, ''There are ACD Gruops Related to this Client''
			else if @idioma = 1
			select 0, ''Tem grupos ACD ligados à este cliente''
			else
			select 0, ''Existen Grupos ACD Relacionados con este Cliente''
		else
			if ( select count(*) from ccCamps where cli_id = @cli_id
			) > 0
				if @idioma = 1
				select 0, ''There are Campaigns Related to this Client''
				else if @idioma = 2
				select 0, ''Tem campanhas ligadas à este cliente''
				else
				select 0, ''Existen Campaas Relacionadas con este Cliente''
			else
			begin
				Delete ccClientes Where cli_id = @cli_id
				if @idioma = 1
				select -1, ''Client: '' + upper(@Descripcion) + '' deleted''
				else if @idioma = 2
				select -1, ''Cliente: '' + upper(@Descripcion) + '' eliminado''
				else
				select -1, ''Cliente: '' + upper(@Descripcion) + '' eliminado''
			end
	end
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMDialer-- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_ADMDialer]
@Descripcion varchar(15),
@dialer_id smallint,
@Port int = 0, -- se cambia tipo de dato
@Status smallint,
@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 3=Eliminar
@provedor_id int=0--by odc
AS
set nocount on
declare @idioma as bit
Select @idioma=isnull(valor,0) from ccSettings where setting_id=27
if @Tipo=1
 begin
	if @provedor_id=0
		select top 1 @provedor_id=provedor_id from cstoProvedor
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion or Puerto=@Port)
	 begin
		select 0, case @idioma when 1 then ''Name in Use'' when 2 then ''O nome está em uso'' else ''Nombre en Uso'' end
		return(0)
	 end
	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id) Select @Descripcion, @Port, @Status, @provedor_id
	select -1, case @idioma when 1 then ''Port: '' + upper(@Descripcion) + '' Added Succesfuly''
	when 2 then ''Porta: '' + upper(@Descripcion) + '' Salva com êxito
''
	else ''Puerto: '' + upper(@Descripcion) + '' Dado de alta'' end
	return(0)
 end

if @Tipo=2
 begin
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion and dialer_id<>@Dialer_id) or 
	exists(select Puerto from ccoDialers where Puerto=@Port and dialer_id<>@Dialer_id)
	 begin
		select 0, case @idioma when 1 then ''Name or port in Use'' when 2 then ''O nome ou a porta estão em uso'' else ''Nombre o puerto en Uso'' end
		return(0)
	 end

	Update ccoDialers set Descripcion= @Descripcion, Puerto=@Port, Status=@Status, provedor_id=@provedor_id Where Dialer_id=@dialer_id
	select -1, case @idioma when 1 then ''Port: '' + upper(@Descripcion) + '' Modified''
	 when 2 then ''Porta: '' + upper(@Descripcion) + '' Editada com êxito''
	else ''Puerto: '' + upper(@Descripcion) + '' Modificado'' end
	return(0)
 end

if @Tipo=3
 begin
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id=@dialer_id)
	select 0, case @idioma when 1 then ''Port in use''
	when 2 then ''A porta está em uso''
	else ''Puerto en uso'' end
	return(0)
	delete ccoDialers Where Dialer_id=@dialer_id		
	select -1, case @idioma when 1 then ''Port: '' + upper(@Descripcion) + '' Port deleted successfully''
	when 2 then ''Porta: '' + upper(@Descripcion) + '' Eliminada com êxito''
	else ''Puerto: '' + upper(@Descripcion) + '' Eliminado exitosamente'' end
	return(0)
 end
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMEspec -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_ADMEspec]
		@Descripcion varchar(40),
		@Inbound_id smallint,
		@cli_id smallint,
		@Tipo tinyint, -- 1=ALTA, 2=Modificacion
		@Show tinyint = 2,
		@Timer tinyint = 2,
		@user_id int = 0
		AS
		set nocount on
		declare @new_Inbound_id smallint
		declare @idioma as bit
		Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
		if @Tipo=1
		 begin
			if exists(select Descripcion from ccInbound where Descripcion = @Descripcion)
			 begin
				select 0, case @idioma when 1 then ''The ACD group already exists''
				when 2 then ''O grupo ACD já existe''
				else ''La especialidad ya existe'' end
				return(0)
			 end
			Insert ccInbound (Descripcion, cli_id, ShowCalifWnd, StartTimerOnHangUp)
			 Values(@Descripcion, @cli_id, @Show, @Timer)
			select @new_Inbound_id = SCOPE_IDENTITY()
			insert into ccCalifCamp (calif_id, cam_id, tipo)
			 select calif_id, @new_Inbound_id as cam_id, 0 as tipo from ccTipoCalif
			if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_Inbound_id, 0, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
			 end
			else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_Inbound_id, 0, 0
			 end
			select -1, case @idioma when 1 then ''ACD group : '' + upper(@Descripcion) + '' Saved succesfully''
			when 2 then ''Grupo ACD : '' + upper(@Descripcion) + '' Salvo com êxito''
			else ''Grupo ACD: '' + upper(@Descripcion) + '' Guardado exitosamente
'' end
			return(0)
		 end
		if @Tipo=2
		 begin
			--Update ccInbound set Descripcion= @Descripcion, ShowCalifWnd=@Show,  StartTimerOnHangUp=@Timer where Inbound_id = @Inbound_id
			Update ccInbound set Descripcion= @Descripcion where Inbound_id = @Inbound_id
			if @Show <> 2 Update ccInbound set ShowCalifWnd=@Show where Inbound_id = @Inbound_id
			if @Timer <> 2 Update ccInbound set StartTimerOnHangUp = @Timer  where Inbound_id = @Inbound_id
			select -1, case @idioma when 1 then ''ACD group : '' + upper(@Descripcion) + '' edited successfully''
			when 2 then ''Grupo ACD : '' + upper(@Descripcion) + '' editado com êxito''
			else ''Grupo ACD : '' + upper(@Descripcion) + '' editado exitosamente'' end
			return(0)
		 end
		if @Tipo=3
		 begin
			if exists(select Inbound_id from ccInboundAgentes where Inbound_id = @Inbound_id)
			 begin
				select 0, case @idioma when 1 then ''There are Agents Related to this ACD group ''
				when 2 then ''Tem agentes atribuídos à este grupo ACD ''
				else ''Existen Agentes Relacionados con este Grupo ACD'' end
				return(0)
			 end
			if exists( select Inbound_id from ccCallsIN where Inbound_id = @Inbound_id)
			 begin
				select 0, case @idioma when 1 then ''There are Call Registries Related to this ACD group ''
				when 2 then ''Tem registros de chamadas ligados à este grupo ACD''
				else ''Existen Registros de Llamadas Relacionados con este grupo ACD'' end
				return(0)
			 end
			Delete ccInbound Where Inbound_id = @Inbound_id
			Delete ccInboundHorarios Where Inbound_id = @Inbound_id
			Delete ccInboundMsgs Where Inbound_id = @Inbound_id
			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A 
				left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and  A.cam_id  = @Inbound_id
			Delete ccSupervisorCam where cam_id  = @Inbound_id and tipo = 0
			select -1, case @idioma when 1 then ''ACD group : '' + upper(@Descripcion) + '' Deleted successfully''
			when 2 then ''Grupo ACD : '' + upper(@Descripcion) + '' eliminado com êxito''
			else ''Grupo ACD: '' + upper(@Descripcion) + '' Eliminado exitosamente
'' end
			return(0)
		 end
		set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMExtension -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMExtension
@NumeroExt varchar(7),
@ext_id smallint, -- Si Tipo =2, aqui viene el ID de la Extension
@Status smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion
AS
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccMonitorExt where Extension = @NumeroExt
		) > 0		
			if @idioma = 1
			select 0, ''Name already in use''
			else if @idioma = 2
			select 0, ''O nome está em uso''
			else
			select 0, ''Nombre en Uso''
		else
		begin
			Insert ccMonitorExt ( Extension, Status ) Values ( @NumeroExt, 1 )
			if @idioma = 1
			select -1, ''Extension: '' + @NumeroExt + '' Saved successfully
''
			else if @idioma = 2
			select -1, ''Extensión: '' + @NumeroExt + '' Guardada exitosamente''
			else
			select -1, ''Ramal: '' + @NumeroExt + '' Salvo com êxito
''
		end
	end
	if ( @Tipo=2 )
	begin
		Update ccMonitorExt set Extension = @NumeroExt, Status=@Status Where ext_id = @ext_id
		if @idioma = 1
		select -1, ''Extension: '' + @NumeroExt + '' Edited successfully''
		else if @idioma = 2
		select -1, ''Ramal: '' + @NumeroExt + '' Editado com êxito''
		else
		select -1, ''Extensión: '' + @NumeroExt + '' Editada exitosamente''
	end
	if ( @Tipo=3 )
	begin
		if ( select count(*) from ccPosicion where ext_id = @ext_id
		) > 0
			if @idioma = 1
			select 0, ''Some workstations are using this extension''
			else if @idioma = 2
			select 0, ''Algumas posições estão usando este ramal''
			else
			select 0, ''Algunas posiciones están usando esta extensión''
		else
			if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id
			) > 0
				if @idioma = 1
				select 0, ''Some keys are using this extension''
				else if @idioma = 2
				select 0, ''Algumas teclas estão usando este ramal''
				else
				select 0, ''Algunas teclas están usando esta extensión''
			else
			begin
				Delete ccMonitorExt Where ext_id = @ext_id
				if @idioma = 1
				select -1, ''Extension: '' + @NumeroExt + '' Deleted successfully
''
				if @idioma = 2
				select -1, ''Extension: '' + @NumeroExt + '' Removed''
				else
				select -1, ''Ramal: '' + @NumeroExt + '' Eliminado com êxito
''
			end
	end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMHorario -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMHorario
@Descripcion varchar(40),
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@HoraInicio tinyint,
@MinInicio tinyint,
@HoraFin tinyint,
@MinFin tinyint,
@Lunes tinyint,
@Martes tinyint,
@Miercoles tinyint,
@Jueves tinyint,
@Viernes tinyint,
@Sabado tinyint,
@Domingo tinyint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion
AS
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccHorarios where Descripcion = @Descripcion) > 0
			if @idioma = 1
			select 0, ''Name already in use''
			else if @idioma = 1
			select 0, ''O nome está em uso''
			else
			select 0, ''Nombre en Uso''
		else
		begin
			Insert ccHorarios ( Descripcion, HoraInicio, MinInicio, HoraFin, MinFin,
						Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo )
					Values ( @Descripcion, @HoraInicio, @MinInicio, @HoraFin, @MinFin,
						@Lunes, @Martes, @Miercoles, @Jueves, @Viernes, @Sabado, @Domingo )
			if @idioma = 1
			select -1, ''Schedule:  '' + upper(@Descripcion) + '' Saved successfullyy''
			else if @idioma = 2
			select -1, ''Horario:  '' + upper(@Descripcion) + '' Salvo com êxito''
			else
			select -1, ''Horario: '' + upper(@Descripcion) + '' Guardado exitosamente''
		end
	end
	if ( @Tipo=2 )
	begin
		Update ccHorarios set Descripcion=@Descripcion, HoraInicio=@HoraInicio, MinInicio=@MinInicio,
					HoraFin=@HoraFin, MinFin=@MinFin,
					Lunes=@Lunes, Martes=@Martes, Miercoles=@Miercoles, Jueves=@Jueves, 
					Viernes=@Viernes, Sabado=@Sabado, Domingo=@Domingo
				where horario_id = @horario_id
		if @idioma = 1
		select -1, ''Schedule:  '' + upper(@Descripcion) + '' Edited successfully''
		else if @idioma = 2
		select -1, ''Horario:  '' + upper(@Descripcion) + '' editado com êxito''
		else
		select -1, ''Horario: '' + upper(@Descripcion) + '' Editado exitosamente
''
	end
	if ( @Tipo=3 )
	begin
		if ( select count(*) from ccInboundHorarios where horario_id = @horario_id ) > 0
			if @idioma = 1
			select 0, ''An ACD group is using this schedule''
			else if @idioma = 2
			select 0, ''Um grupo ACD está usando este horario''
			else
			select 0, ''Un grupo ACD está usando este horario''
		else
		begin
			Delete ccHorarios Where horario_id = @horario_id
			if @idioma = 1
			select -1, ''Schedule:  '' + upper(@Descripcion) + '' Deleted successfully
''
			else if @idioma = 2
			select -1, ''Horário:  '' + upper(@Descripcion) + '' Eliminado com êxito
''
			else
			select -1, ''Horario: '' + upper(@Descripcion) + '' Eliminado exitosamente
''
		end
	end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES  ccsp_ADMInboundHorarios-- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMInboundHorarios
@Inbound_id smallint,
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40)
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	select @Descripcion=Upper(Descripcion) from ccHorarios where horario_id=@horario_id
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccInboundHorarios where Inbound_id = @Inbound_id and horario_id=@horario_id
		) > 0
			if @idioma = 1
			select 0, ''Schedule Already Assigned''
			else if @idioma = 2
			select 0, ''Horário já atribuído''
			else
			select 0, ''Horario ya Asignado''
		else
		begin
			Insert ccInboundHorarios (Inbound_id, Horario_id  ) Values ( @Inbound_id, @horario_id )
			if @idioma = 1
			select -1, ''Schedule: '' + @Descripcion + '' Assigned successfully''
			else if @idioma = 2
			select -1, ''Horário: '' + @Descripcion + '' Atribuído com êxito''
			else
			select -1, ''Horario: '' + @Descripcion + '' Asignado exitosamente
''
		end
	end
	if ( @Tipo=3 )
	begin
		Delete ccInboundHorarios where Inbound_id = @Inbound_id and horario_id=@horario_id
		if @idioma = 1
		select -1, ''Schedule: '' + @Descripcion + '' Unassigned successfully
''
		else if @idioma = 2
		select -1, ''Horário: '' + @Descripcion + '' Eliminada com êxito''
		else
		select -1, ''Horario: '' + @Descripcion + '' Desasignado exitosamente''
	end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMInboundMsgs -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMInboundMsgs
@Inbound_id smallint,
@msg_id smallint,
@orden smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40)
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	select @Descripcion=Upper(msgFile) from ccMsgFiles where msg_id=@msg_id
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccInboundMsgs where Inbound_id = @Inbound_id and msg_id=@msg_id and orden=@orden
		) > 0
			if @idioma = 1
			select 0, ''Message Already Assigned''
			else if @idioma = 2
			select 0, ''Mensagem já atribuída''
			else
			select 0, ''Mensaje ya Asignado''
		else
		begin
			Insert ccInboundMsgs ( Msg_id, Inbound_id, orden  ) Values ( @msg_id, @Inbound_id, @orden )
			if @idioma = 1
			select -1, ''Message: '' + @Descripcion + '' Assigned successfully''
			else if @idioma = 2
			select -1, ''Mensagem: '' + @Descripcion + '' Atribuída com êxito''
			else
			select -1, ''Mensaje: '' + @Descripcion + '' Asignado exitosamente''
		end
	end
	if ( @Tipo=3 )
	begin
		Delete ccInboundMsgs where Inbound_id = @Inbound_id and msg_id=@msg_id and orden=@orden
		if @idioma = 1
		select -1, ''Message: '' + @Descripcion + '' Unassigned successfully''
		else if @idioma = 2
		select -1, ''Mensagem : '' + @Descripcion + '' Eliminado com êxito''
		else
		select -1, ''Mensaje: '' + @Descripcion + '' Desasignado exitosamente''
	end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMKeyPBX -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMKeyPBX
@NumeroKey smallint,
@ptopbx_id smallint,
@ext_id smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Delete
AS
declare @numKey as varchar(3)
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	select @numKey = convert(varchar(3), @NumeroKey)
	if ( @Tipo=1 )
	begin
		if ( select count(*) from ccTeclaExtensionPuerto where num_tecla = @NumeroKey and ptopbx_id = @ptopbx_id
		) > 0
			if @idioma = 1
			select 0, ''Key already in use''
			else if @idioma = 2
			select 0, ''A tecla está em uso''
			else
			select 0, ''Tecla en Uso''
		else
			if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id
			) > 0
				if @idioma = 1
				select 0, ''Extension already in use''
				else if @idioma = 2
				select 0, ''O ramal está em uso''
				else
				select 0, ''Extension en Uso''
			else
				Insert ccTeclaExtensionPuerto ( num_tecla, ptopbx_id, ext_id )
						Values ( @NumeroKey, @ptopbx_id, @ext_id )
				if @idioma = 1
				select -1, ''Key: '' + @numKey + '' Saved successfully''
				else if @idioma = 2
				select -1, ''Tecla: '' + @numKey + '' Salva com êxito''
				else
				select -1, ''Tecla: '' + @numKey + '' Guardada exitosamente''
	end
	if ( @Tipo=2 )
	begin
		if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id and num_tecla <> @NumeroKey  
		) > 0
			if @idioma = 1
			select 0, ''Extension already in use''
			else if @idioma = 2
			select 0, ''O ramal está em uso''
			else
			select 0, ''Extension en Uso''
		else
			Update ccTeclaExtensionPuerto set ptopbx_id=@ptopbx_id, ext_id=@ext_id
					where num_tecla = @NumeroKey --and ptopbx_id = @ptopbx_id
			if @idioma = 1
			select -1, ''Key: '' + @numKey + '' Edited successfully''
			else if @idioma = 2
			select -1, ''Tecla: '' + @numKey + '' Editada com êxito''
			else
			select -1, ''Tecla: '' + @numKey + '' Editada exitosamente''
	end
	if ( @Tipo=3 )
	begin
		Delete ccTeclaExtensionPuerto where num_tecla = @NumeroKey and ptopbx_id=@ptopbx_id and ext_id=@ext_id
		if @idioma = 1
		select -1, ''Key: '' + @numKey + '' Deleted successfully''
		else if @idioma = 2
		select -1, ''Tecla: '' + @numKey + '' Eliminada com êxito''
		else
		select -1, ''Tecla: '' + @numKey + '' Eliminada exitosamente''
	end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMKeyPBX_ext -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMKeyPBX_ext
@extension varchar(7),
@NumeroKey smallint,
@ptopbx_id smallint
AS
declare @ext_id as smallint
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
	select @ext_id = ext_id from ccMonitorExt where extension=@extension
	if ( @ext_id is not null )
	begin
		if ( select count(*) from ccTeclaExtensionPuerto where num_tecla= @NumeroKey and ptopbx_id = @ptopbx_id 
		) > 0
		begin
			update ccTeclaExtensionPuerto set ext_id=@ext_id where num_tecla= @NumeroKey and ptopbx_id = @ptopbx_id 
			if @idioma = 1
			select -1, ''Key: '' + convert(varchar(4), @NumeroKey) +''  Edited successfully''
			else if @idioma = 2
			select -1, ''Tecla: '' + convert(varchar(4), @NumeroKey) +''  Editada com êxito''
			else
			select -1, ''Tecla: '' + convert(varchar(4), @NumeroKey) +''  Editada exitosamente''
		end
		else
			if ( select count(*) from ccTeclaExtensionPuerto where ext_id = @ext_id
			) > 0
				if @idioma = 1
				select 0, ''Extension already in use''
				else if @idioma = 2
				select 0, ''O ramal está em uso''
				else
				select 0, ''Extension en Uso''
			else
			begin
				Insert ccTeclaExtensionPuerto ( num_tecla, ptopbx_id, ext_id )
						Values ( @NumeroKey, @ptopbx_id, @ext_id )
				if @idioma = 1		
				select -1, ''Key: '' + convert(varchar(4), @NumeroKey) +''  Saved successfully''
				else if @idioma = 2	
				select -1, ''Tecla: '' + convert(varchar(4), @NumeroKey) +''  Salva com êxito''
				else
				select -1, ''Tecla: '' + convert(varchar(4), @NumeroKey) +''  Guardada exitosamente''
			end
	end'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_ADMPosicion -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_ADMPosicion
@Computer varchar(40),
@pos_id smallint,
@ext_id smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion
AS
set nocount on
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
if @Tipo=1
 begin
	if exists(select Computer from ccPosicion where Status=1 and Computer=@Computer)
	 begin
		select 0, case @idioma when 1 then ''Name already in use'' when 2 then ''O nome está em uso'' else ''Nombre en Uso'' end
		return(0)
	 end
	Insert ccPosicion (Computer, ext_id) Select @Computer, @ext_id
	select -1, case @idioma when 1 then ''Workstation: '' + upper(@Computer) + '' Saved successfully''
	when 2 then ''Posição: '' + upper(@Computer) + '' Salva com êxito''
	else ''Posicion: '' + upper(@Computer) + '' Guardada exitosamente'' end
	return(0)
 end
if @Tipo=2
 begin
	Update ccPosicion set Computer=@Computer, ext_id=@ext_id where Status=1 and pos_id=@pos_id
	select -1, case @idioma when 1 then ''Workstation: '' + upper(@Computer) + '' Edited successfully''
	when 2 then ''Posição: '' + upper(@Computer) + '' Editada com êxito''
	else ''Posicion: '' + upper(@Computer) + '' Editada exitosamente'' end
	return(0)
 end
if @Tipo=3
 begin
	Update ccPosicion Set Status=0 Where pos_id=@pos_id
	select -1, case @idioma when 1 then ''Workstation: '' + upper(@Computer) + '' Deleted successfully''
	when 2 then ''Posição: '' + upper(@Computer) + '' Eliminada com êxito''
	else ''Posicion: '' + upper(@Computer) + '' Eliminada exitosamente'' end
	return(0)
 end
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_OUTGetCallsInfo_byCAMP -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE ccsp_OUTGetCallsInfo_byCAMP
@CamID int
AS
declare @nAnswer int, @nBusy int, @nNoAnswer int, @nFaxModem int
declare @mToday as smalldatetime
declare @bRestarting as tinyint
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
select @bRestarting = 1
if @bRestarting = 0 begin
	select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
	SELECT
		@nAnswer 	= count( case tipoResDial_id when 1 then 1 else null end), 
		@nBusy 	= count( case tipoResDial_id when 2 then 1 else null end),
		@nNoAnswer	= count( case tipoResDial_id when 3 then 1 else null end), 
		@nFaxModem	= count( case tipoResDial_id when 4 then 1 else null end) 
	FROM ccoLogDials
	WHERE cam_id=@CamID
	AND fecha >  @mToday
	if @idioma = 1
	SELECT ''Answered''=@nAnswer, ''Busy''=@nBusy, ''Not Answer''=@nNoAnswer, ''Fax/Modem''=@nFaxModem
	else if @idioma = 2
	SELECT ''Contatadas''=@nAnswer, ''Ocupadas''=@nBusy, ''Não atendidas''=@nNoAnswer, ''Fax/Modem''=@nFaxModem
	else
	SELECT ''Contestadas''=@nAnswer, ''Ocupadas''=@nBusy, ''No Conestadas''=@nNoAnswer, ''Fax/Modem''=@nFaxModem
end else begin
	if @idioma = 1
	SELECT ''Answered''=0, ''Busy''=0, ''Not Answer''=0, ''Fax/Modem''=0
	else if @idioma = 2
	SELECT ''Contatadas''=0, ''Ocupadas''=0, ''Não atendidas''=0, ''Fax/Modem''=0
	else
	SELECT ''Contestadas''=0, ''Ocupados''=0, ''NO Conestan''=0, ''Fax/Modem''=0
end
/*
-- CONTESTADAS
SELECT @nAnswer=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 1
AND cam_id=@CamID
AND fecha >  @mToday
-- OCUPADOS
SELECT @nBusy=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 2
AND cam_id=@CamID
AND fecha >  @mToday
-- NO CONTESTA
SELECT @nNoAnswer=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 3
AND cam_id=@CamID
AND fecha >  @mToday
-- FAX_MODEM
SELECT @nFaxModem=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 4
AND cam_id=@CamID
AND fecha >  @mToday
SELECT ''Contestadas''=@nAnswer, ''Ocupados''=@nBusy, ''NO Conestan''=@nNoAnswer, ''Fax/Modem''=@nFaxModem
*/'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_getCampDialInfo -- Version BD 119.122 -- '
    	set @Sql= 'ALTER procedure [dbo].[ccsp_getCampDialInfo]
@cam_id as integer = 0
AS
declare @idioma as bit
declare @msg as varchar(40)
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27
if @idioma = 1
select @msg = ''Last campaigns summary retrieval''
else if @idioma = 2
select @msg = ''Última consulta do resumo das campanhas''
else
select @msg = ''Última consulta de resumen de campañas''
if (select count(*) from ccSettings where setting_id = 24) = 0 begin
	insert ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) values (24, convert(varchar(25), dateadd(ss, -10, getdate()), 121), @msg, 1, ''GRL'',''Detalle'',''description'',0)	
end
if (select datediff(ss, (select valor from ccsettings where setting_id = 24), getdate())) > 60 begin
	update ccsettings set valor = convert(varchar(25), getdate(), 121) where setting_id = 24
	delete ccCampsDialInfo
	insert ccCampsDialInfo
	select c.cam_id, isnull(t.nCalls, 0), isnull(t.nAnswer, 0), isnull(t.nBusy, 0), isnull(t.nNoAnswer, 0),
			 isnull(t.nMachine, 0), isnull(t.nFax, 0), isnull(t.nNoTone, 0), isnull(t.nCongestion, 0), isnull(t.nOthers, 0)
	from ccCamps c left join 
	(
		select cam_id, count(*) as nCalls, 
		count(case tiporesdial_id when 1 then 1 else null end) as nAnswer, 
		count(case tiporesdial_id when 2 then 1 else null end) as nBusy, 
		count(case tiporesdial_id when 3 then 1 else null end) as nNoAnswer, 
		count(case tiporesdial_id when 11 then 1 else null end) as nMachine, 
		count(case tiporesdial_id when 4 then 1 else null end) as nFax, 
		count(case tiporesdial_id when 5 then 1 else null end) as nNoTone,
		count(case tiporesdial_id when 12 then 1 else null end) as nCongestion, 
		count(case when tiporesdial_id not in (1, 2, 3, 4, 5, 11, 12) then 1 else null end) as nOthers 
		from ccoLogDials where fecha > convert(varchar(11), getdate(), 101) 
		group by cam_id
	) t on c.cam_id = t.cam_id
end
select * from ccCampsDialInfo where (cam_id = @cam_id or @cam_id = 0)'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_getVersion -- Version BD 119.122 -- '
    	set @Sql= '-- =============================================
/*Catalogo de errores:
-1 / ERROR. ??? -- Este error no es controlado, es una excepcion del store, server, segun mande la alerta es lo que se mostrara
-2 / ERROR. Modulo no valido -- Cuando en el parametro de modulo no se ingresa BD|DB, AVRS, ALL
-3 / ERROR. Version no Valida para ''BD/AVRS''. Version Actual: ''#Version'' -- Cuando se quiere generar una versión que no es mayor a la actual
-4 / ERROR. generado al actualizar a version ''#Version'' -- Cuando se presento un problema al hacer el update de la version, por lo cual no se actualizo
*/
ALTER procedure [dbo].[ccsp_getVersion]
@Module varchar(3) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma bit
select @Idioma = cast(valor as bit) from ccSettings where setting_id = 27
if upper(isnull(@Module, '''')) not in (''BD'', ''ADM'', ''AGT'', ''ALL'', ''BDF'')
 begin
	select ''-2'' ID, case @Idioma when 1 then ''ERROR. Invalid module''
	when 2 then ''ERRO. Módulo inválido''
	else ''ERROR. Invalid Module'' end [Description]
	return(0)
 end
declare @nVersion varchar(30)
select @nVersion = cast(valor as varchar(15)) from ccSettings where setting_id = 77
BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9), @version_3 varchar(6), @version_4 varchar(6)
	declare @Prueba table
	 (id int,
	  value nvarchar(100)
	 )
	 insert into @Prueba
		 select * from  fn_RIASplitDelimited (@nVersion,''.'')
	 IF not exists (select value from @Prueba where id = 4) begin
		update ccsettings
		set valor = valor +''.00''
		where setting_Id = 77
		insert into @Prueba (value)
		values(''00'')
	 end
END TRY
BEGIN CATCH
	select ''-1'' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH
if isnull(@Version, 0) = 0
 begin
	select @version_1 = value from @Prueba where id = 1
	select @version_2 = value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = value from @Prueba where id = 4
	if upper(@Module) = ''ALL'' or upper(@Module) = ''BDF'' begin
		if  upper(@Module) = ''ALL''
			select @version_1 + ''.'' + @version_2 + ''.'' + @version_3+''.''+ @version_4
		else if  upper(@Module) = ''BDF''
			select @version_1 + ''.'' + @version_4
		return(0)
	end
	else
		select @version = cast(case upper(@Module) when ''BD'' then @version_1
		when ''ADM'' then @version_2 when ''AGT'' then @version_3 end as int)
		select @version Version
		return(@version)
 end
--return
if upper(@Module) = ''BD'' and (@Version <= cast(@version_1 as int) or (@Version - cast(@version_1 as int))>1)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Invalid version for DB current version: '' + @version_1
	when 2 then ''ERRO. Versão inválida para BD, versão atual: '' + @version_1
	else ''ERROR. Versión no válida para BD, versión actual: '' + @version_1
	end [Description]
	return(0)
 end
if @Version <= cast(case upper(@Module) when ''BD'' then @version_1
when ''ADM'' then @version_2 else @version_3 end as int)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Invalid version for:  '' + @Module + ''. Current version : '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	 when 2 then ''ERRO. Versão inválida para '' + @Module + ''. Versão atual: '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	else ''ERROR. Versión no válida para '' + @Module + ''. Versión actual: '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	end [Description]
	return(0)
 end
	select @version_1 = value from @Prueba where id = 1
	select  @version_2 =value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = isnull(max(value),0) from @Prueba where id = 4
if upper(@Module) = ''BD'' set @version_1 = @Version
else if upper(@Module) = ''ADM'' set @version_2 = @Version
else if upper(@Module) = ''AGT'' set @version_3 = @Version
else set @version_4 = @Version
set @nVersion = @version_1 + ''.'' + @version_2 + ''.'' + @version_3 + ''.'' + @version_4
update ccSettings set valor = @nVersion where setting_id = 77
if @@rowcount = 1
	select ''0'' ID, ''Actualizado a version: '' + @nVersion [Description]
else
	select ''-4'' ID, case @Idioma when 1
	then ''ERROR occurred while upgrading to version:  '' + @nVersion
	when 2 then ''ERRO encontrado ao atualizar a versão: '' + @nVersion
	else ''ERROR generado al actualizar a versión: '' + @nVersion
	end [Description]
return (0)
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_RIA_ABCCamps -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int,
@Descripcion varchar(40),
@Cam_id varchar(1000),
@Activa tinyint,
@IDArea smallint = null,
@frame tinyint, 
@MirrorInbound_Id smallint = null
as
set nocount on
if @option = 0
 begin
	 select cam_id,ISNULL(cam_descripcion,'''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
	 from ccCamps as CAMP with(nolock) 
	 left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
	 return(0)
 end
if @option = 1 -- select Camp
 begin
	 select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0)
	 from ccCamps a1 with(nolock) 
	  inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
	  inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	 where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
	 return(0)
 end
if @option = 4 --Delete
 begin
 	 if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
	  begin
		declare @error varchar(70)
		Select @error=case valor when 1 then ''There is an ACD group assigned to this campaign'' 
		when 2 then ''Tem um grupo ACD ligado à esta campanha'' 
		 else ''Existe un grupo ACD asociado a esta campaña'' end
		from ccsettings with(nolock) where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
	  end
	 delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
	 insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
	 Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
	 Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
	 delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
	 delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
	 return(0)
 end
if @option = 2 --Insert
 begin
	declare @new_cam_id smallint
	if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
	 begin
		select -1 --, ''Nombre en Uso''
		return(0)  
	 end
	-- ODC: la campaña siempre esta activa
	set @Activa = 1
	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end
	if @@rowcount = 1
	select @new_cam_id = scope_identity()
	else
	 begin
		select -2 --, ''Error al crear campaña''
		return(0)
	 end
	if isnull(@MirrorInbound_Id, 0)<>0
	 begin
		if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
		 begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
		 end
		update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
	 end
	insert into ccoDialerCamp (dialer_id, cam_id) 
	select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
	insert into ccCalifCamp (calif_id, cam_id, tipo) 
	select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1
	If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
	 begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
	 end
	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1
	--inserta la lista negra por default
	if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
	begin
		declare @tempId as int
		DECLARE @dnclId TABLE 
		(
		  id int 
		);
		insert into @dnclId
		exec dbo.ccsp_RIACATBList null, null, 5
		select @tempId=id from @dnclId;
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end
	select @new_cam_id
	return(0)
 end
if @option = 3 -- Update
 begin
	 if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
	  insert into ccRIAGraphics (frame,type_id) values (@frame,1)
	 Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id
	 update ccRIACampsGraph with(rowlock)
	  set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
	  where cam_id = @Cam_id
	 return(0)
 end
 if @option = 5 --Obtener relaciones de campañas - campañas
   begin
      if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
	 begin
		select -3 -- Campaña invalida
		return(0)
	 end
	if @descripcion=0
		set @descripcion = null
	update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
	else
	 begin
		delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)
	 end
	return(0)
   end
if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end
return(0)
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES ccsp_RIA_ABCLog -- Version BD 119.122 -- '
    	set @Sql= 'ALTER procedure [dbo].[ccsp_RIA_ABCLog]
@option tinyint,
@areaName varchar(50)=null,
@operationType tinyint = null,
@login varchar(20) = null,
@moduleId int=null,
@value varchar(250)=null,
@target varchar(250)=null,
@operationDateIni smalldatetime = null,
@operationDateFin smalldatetime = null,
@top int = 0
as
set nocount on
if @option=1 -- muestra todo
 begin
	select log_id, areaName, operationDate, operationType, login, module_id, value, target
	from ccRIALog with(nolock)
	return(0)
 end
if @option=2 -- insert
 begin
	declare @areaNameValue as varchar(50)
	set @areaNameValue = @areaName
	if (left(@areaName,1) = ''!'')
	 begin
		select @areaNameValue = areaName
		from dbo.ccRIACat_Areas AS AREAS WITH(NOLOCK)
		where AREAS.IDArea = right(@areaName,len(@areaName)-1)
	 end
	INSERT INTO ccRIALog VALUES(@areaNameValue, GETDATE(), @operationType, @login, @moduleId, @value, @target)
	return(0)
 end
declare @lang tinyint
select @lang = valor from ccsettings where setting_id=27
if @option=3 -- muestra información por filtros (System>Log) // Fechas
 begin
	set rowcount @top
	select L.log_id, L.areaName, L.operationDate, 
	case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
	when 1 then substring(o.descripcion, charindex(''|'', o.descripcion)+1, len(o.descripcion))
	 else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+2, len(o.descripcion)) END operationType, L.login, 
	case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
	 when 1 then substring(m.descripcion, charindex(''|'', m.descripcion)+1, len(m.descripcion))
	 else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+2, len(m.descripcion)) END module_id, L.value, L.target
	from CCRIALOG L join ccRIALog_Module M with(index(IX_ccRIALog_Module)) on L.module_id = M.module_id join ccRIALog_Operation O with(index(IX_ccRIALog_Operation)) on L.operationType = O.operationType
	where L.operationType = case isnull(@operationType, 0) when 0 then L.operationType else @operationType end
	 and L.login = case isnull(@login, '''') when '''' then L.login else @login end
	 and L.module_id = case isnull(@moduleId, 0) when 0 then L.module_id else @moduleId end
	 and L.target = case isnull(@target, '''') when '''' then L.target else @target end
	 and L.operationDate >= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
		isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, -1, @operationDateIni) else L.operationDate end
	 and L.operationDate <= case when isnull(@operationDateIni, ''19000101'') <> ''19000101'' and 
		isnull(@operationDateFin, ''19000101'') <> ''19000101'' then dateadd(minute, 1, @operationDateFin) else L.operationDate end
	order by L.operationDate desc
	return(0)
 end
if @option=4 -- Catalogo de modulos
 begin
	select m.module_id, o.operationType, 
	case @lang when 0 then SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion)-1)
	 when 1 then substring(m.descripcion, charindex(''|'', m.descripcion)+1, len(m.descripcion))
	 else SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion)+2, len(m.descripcion)) END as mDescripcion, 
	 case @lang when 0 then SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion)-1)
	 when 1 then substring(o.descripcion, charindex(''|'', o.descripcion)+1, len(o.descripcion))
	 else SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion)+2, len(o.descripcion)) END as oDescripcion
	from ccRIALog_Operation o with(index(IX_ccRIALog_Operation)) join ccRIALog_Cat_Relation r on o.operationType = r.operationType
	 join ccRIALog_Module m with(index(IX_ccRIALog_Module)) on r.module_id = m.module_id
	UNION
	select 0, -1, case @lang when 0 then ''-TODAS-'' when 2 then ''-TODAS-'' else ''-ALL-'' END, ''-''
	UNION
	select 0, 0, case @lang when 0 then ''-TODAS-'' when 2 then ''-TODAS-'' else ''-ALL-'' END, case @lang when 0 then ''-TODAS-'' when 2 then ''-TODAS-'' else ''-ALL-'' END
	UNION
	select module_id, 0, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	when 1 then substring(descripcion, charindex(''|'', descripcion)+1, len(descripcion))
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+2, len(descripcion)) END as descripcion, 
	 case @lang when 0 then ''-TODAS-'' when 2 then ''-TODAS-'' else ''-ALL-'' END from ccRIALog_Module with(index(IX_ccRIALog_Module)) 
	UNION
	select module_id, -1, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 when 1 then substring(descripcion, charindex(''|'', descripcion)+1, len(descripcion))
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+2, len(descripcion)) END as descripcion, ''-'' 
	 from ccRIALog_Module with(index(IX_ccRIALog_Module)) 	
    order by mDescripcion, oDescripcion
	return(0)
 end
if @option=5 -- Catalogo de operaciones
 begin
	select operationType, case @lang when 0 then SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion)-1)
	 when 1 then substring(descripcion, charindex(''|'', descripcion)+1, len(descripcion))
	 else SUBSTRING(descripcion, CHARINDEX(''|'', descripcion)+2, len(descripcion)) END as descripcion
	from ccRIALog_Operation with(index(IX_ccRIALog_Operation))
	union
	select 0, case @lang when 0 then ''-TODAS-'' when 2 then ''-TODAS-'' else ''-ALL-'' END 
	order by 2
	return(0)
 end
set nocount off'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES Validate y Detalle ccSettings -- Version BD 119.122 -- '
    	set @Sql= 'update ccSettings set detalle = ''Idioma en que apareceran tanto agente como admin RIA.  (0 español - 1 inglés - 2 portugués)'' where setting_id=27
update ccSettings set validate = ''^[0-2]$'' where setting_id=27
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES update ccMenus -- Version BD 119.122 -- '
    	set @Sql= 'update ccMenus set menu_descrip = ''Recursos Humanos|Human Resources|Recursos humanos'', release =''85992a0728f5b837f6ca7b289b5f2219d318673b591808fd2d44cc7f1bcc2e5fd9c5a1e24b60ba10af119cb8997cd07b7f4502056f8fbb4993cb77fb72f29a14'' where menu_id=2
update ccMenus set menu_descrip = ''Gestión de áreas|Areas Management|Gestão de áreas'', release =''ec86f9280f3ddb0487f2194a2316df4bdf6be467aed6bab26216dca31fb10be7568ccfabf960ea1fa355bec26107d94b3353423b9ee4f82886e99bda726d5a20'' where menu_id=3
update ccMenus set menu_descrip = ''Gestión de grupos de trabajo|Workgroups Management|Gestão de grupos de trabalho'', release =''8a54b89d53297e7871a0c4072a3de33ad28a3b8ae346ac256b59304fe1e28c27d9aa12d201f9e9a3d0bb65a9cc63292a9f1483960a4a10796b3faa1abb5a9df6616f47a1987696d58ff9fea6e532116996b83090c715f90e26ac5ed11def5de1'' where menu_id=4
update ccMenus set menu_descrip = ''Permisos de agente|Agent Permissions|Autorizações do agente'', release =''e2646c409e1f92d42eb87ec99cf63205a63e2368419e782295eb430d8e40d8f2b34bb709004ed801ab31055a73618c184ec10aa0fc27c9f901e43852b12fbd68'' where menu_id=5
update ccMenus set menu_descrip = ''Tipos de no disponible|Unavailable Options|Tipos de não disponível'', release =''c2c6db193b45ba8a6691c7c974c021cc210696c4d52c89c98e2500ea567869c03f4d867bf43d90be2914bc638a5ff3b988c522e66a7abc24ef79ac426c65aef3cf6c1acfb6c769699fbad7e7c432eafd'' where menu_id=7
update ccMenus set menu_descrip = ''Chat con agentes|Chat with Agents|Conversa com agente '', release =''2ce5aaa93c9e021af981814fa26a38f799259c5e363d8886bec0687c4facbd4d07616ca84448dea17d1cca2c63a1486d135d0c4b210f4a82f15d19086bdf4b11'' where menu_id=8
update ccMenus set menu_descrip = ''Campañas|Campaigns|Campanhas'', release =''9e175f3ecac1fb5782650d8f8de8ebbd78463cffd588e0a0049b71195436fdde'' where menu_id=9
update ccMenus set menu_descrip = ''Configuración|Configuration|Configuração'', release =''9f54271c454bdc582cee3c666e3f98e13359c31f515f1feea3feee758f2aaee6beb9d34296c7f012f5daca2c694568f1'' where menu_id=10
update ccMenus set menu_descrip = ''Horarios|Schedules|Horários'', release =''04ad7a6c0a683dc3f297463c7dbb0296470a3f2aa02f8ba77a4d131da5a995f7'' where menu_id=11
update ccMenus set menu_descrip = ''Inicio automático|Auto Start Configuration|Início automático'', release =''b13bc6b2835686c7e094bcd29f3adb216303782ac1b013f763d91b3a2d23f40509e4beffc28866cfd98220abf584f7039f0228489f62fabda8810125bea8fc6612094bf44cfcd90c383d3789fdfa7047'' where menu_id=12
update ccMenus set menu_descrip = ''Carga de base de datos|Data Import|Carga do banco de dados'', release =''644f3f9a7013f33219aae30ca25565240c0234b9a50a88494c16bb33bf9d3303cd7bfc3fcf71df6b57236f62c6ac1338bd64a09bb9f827c46c06f4d443fa8b92'' where menu_id=13
update ccMenus set menu_descrip = ''Asignación de puertos|Dialer Ports Assignment|Atribuição de portas'', release =''0136b908696acb11b0399e25cff6f54e05417e431b705f8d444decd195da4b4acb6d1355287561cd3df2511b3e7ec9485c760d20c8834f2b818b43bc488f66a496e604cb9779ad97924c8add6c273e96'' where menu_id=14
update ccMenus set menu_descrip = ''Calificaciones|Dispositions|Classificações'', release =''54d108e6439d9428e2b8fd3e9f91fdee55eafa4c392e4ff2edcbd775f8d325e86b9ed84feeafab3bd3f074530714beca'' where menu_id=15
update ccMenus set menu_descrip = ''Grupos ACD|ACD Groups|Grupos ACD'', release =''451fb584247906528fa2581818dea278fced4d7127f64869049871bf1c89af9f2988611511c34bad672cdb1cab57d5a1'' where menu_id=16
update ccMenus set menu_descrip = ''Configuración|Configuration|Configuração'', release =''9f54271c454bdc582cee3c666e3f98e13359c31f515f1feea3feee758f2aaee6beb9d34296c7f012f5daca2c694568f1'' where menu_id=17
update ccMenus set menu_descrip = ''Horarios|Schedules|Horários'', release =''04ad7a6c0a683dc3f297463c7dbb0296470a3f2aa02f8ba77a4d131da5a995f7'' where menu_id=18
update ccMenus set menu_descrip = ''Mensajes automáticos|Automatic Messages|Mensagens automáticas'', release =''6d88ac1ff1c050478fb6151462e81ed619809b45d00e0111d5b6871bd2b894b30b4d2ea885cd44f8f4f3830b5821f01915409e098e19ae4b8ac37d1567ce8f6d5f4646a54c8ba885319383a64da3e19b'' where menu_id=19
update ccMenus set menu_descrip = ''Números DNIS|DNIS Assignment|Números DNIS'', release =''96aefc1db17d45991e4fac4e2bcbd1cb452125bd0ccb77984570201f14813d2ee87c4db1ae88c046200154e8741a6ba0'' where menu_id=20
update ccMenus set menu_descrip = ''Calificaciones|Dispositions|Classificações'', release =''54d108e6439d9428e2b8fd3e9f91fdee55eafa4c392e4ff2edcbd775f8d325e86b9ed84feeafab3bd3f074530714beca'' where menu_id=21
update ccMenus set menu_descrip = ''Listas Negras|Do Not Call List|Listas negras'', release =''657939de6fb0d4ed3d69cc97c831307c00bf475d844cf6bda2d3cfaf07e9e1044456b2733ef384c81957984da98b7153'' where menu_id=22
update ccMenus set menu_descrip = ''Carga|Import|Carregamento'', release =''51d8bf17e0cce18c64e003020eda7ee0ead76ce65c5dcf2b7d23a70d3f0be2d7'' where menu_id=23
update ccMenus set menu_descrip = ''Catálogo|Management|Catálogo'', release =''614c124db2384775a4a2011f900ffc30dd119a9857e44d593397d39b6a71a1ef'' where menu_id=24
update ccMenus set menu_descrip = ''Historial de carga|Import Log|Historial de carga'', release =''b14dfaa33570212ebf08ddc649b950b5f235f7630e0068ee02417bc27e3959db193f1c85630e54a6bf10e3edd87ba70a9f4f9643e1567c96ccc3e0340fccd8be'' where menu_id=26
update ccMenus set menu_descrip = ''Búsqueda|Search|Busca'', release =''71c4049b32adff34554c0bd223085689f6c7d698686afedfb505a15f517dcd26'' where menu_id=27
update ccMenus set menu_descrip = ''General|General|Geral'', release =''9069f719716240d7b738cd6f41a60f033a81003c46e5336ffdcfe1ca422d0725'' where menu_id=28
update ccMenus set menu_descrip = ''Permisos de menú|Administrator Menu Rights|Autorizações do menu'', release =''5c56447be49b20be68afcc90e3c04e816a76a1803de48898ab149f77e3c411f9fad2cd7e394972cd2eec9c0f0ddd1ab1e280e70d3735b2bb9b6edabd6d8e066358895f5b5da2a499633ab8a6ac8b60ea'' where menu_id=29
update ccMenus set menu_descrip = ''Configuraciones avanzadas|Advanced Configuration|Configurações avançadas'', release =''5698b9e6ebf6ed35823013e0c9937b15918c4c76d786b1c6cd80bd5611467283e49ca208bf37b2fdc0fddfd559851a0f288172521b34cf58c80e1cedee617f83579bc5c6a5ce4b97c6a5e20ed28757fa'' where menu_id=30
update ccMenus set menu_descrip = ''Estado del call center|Call Center Status|Estado da central de atendimento'', release ='''' where menu_id=31
update ccMenus set menu_descrip = ''Sistema|System|Sistema'', release =''01ecf72c0d94f3a93cc6754f9e44b9a6334b0f3d8a6373bde2bab0dcd96cf6cc'' where menu_id=32
update ccMenus set menu_descrip = ''Catálogo de mensajes|Audio Messages Import|Catálogo de mensagens'', release =''d97175d74af3b9d9152f1c606b5763e2663a6cd01d5313cef307cf52e8036216245514f831f31a7eeb5d7facecf51c1395154313732bbc18ca393c56797aafc0c9460b86431a38299a53e21bb5358719'' where menu_id=35
update ccMenus set menu_descrip = ''Puertos de marcación|Dialer Ports|Portas de discagem'', release =''d2cbc14611cb43181d724b13d76fd12d35bdec94a4340724b1427088491a42925df4891439029f8592b9014bd46ba0df816ed04e73f87499f5538c556847167b'' where menu_id=36
update ccMenus set menu_descrip = ''Tarifas|Carrier Rates|Taxas'', release =''89d5ec707d341b1fb374ea97aa1247864c50b2ebf808305ebade3a3131bc3cf0'' where menu_id=38
update ccMenus set menu_descrip = ''Acerca de ...|About|Acerca de…'', release =''793625d951fb18db179715d3163af4153252efff0a6460fd64bd870ee6b71d8c31f3f9c7379a063a072a23fd78e14f7b'' where menu_id=40
update ccMenus set menu_descrip = ''Monitoreo de llamada|Call Monitoring|Monitoramento da chamada'', release =''3019576729a6fef6b140465b6baf9ad8550bc41e0de9a2ec407a94fb88b5309430437d3d8da8467fcdcb3ec7a3f356d33751221eb183aa455c6389f2e816c504'' where menu_id=41
update ccMenus set menu_descrip = ''Configuración de posiciones|Workstations Configuration|Configuração de posições'', release =''9f54271c454bdc582cee3c666e3f98e1bf5aa306fd577f2af8b6c647b64aeef3666b2398e73dec6f43b4f60729ffbafaff4d95faf43142bb7f8cb4398176ea1737df2f5bdc8824b571eef9e164cfb1fd4c01463111aeeb67ee371d59e665f40b'' where menu_id=42
update ccMenus set menu_descrip = ''Historial de cambios|Administrator Changes Log|Histórico de modificações'', release =''b14dfaa33570212ebf08ddc649b950b5c5ca6292b23a79e8b39d3ad3b12d67ab4a962ce3d75eb93a84925aa5c67be951f14270e2e2727194d51dd8497d3c227bc86f026f47f16bca421657706c197f2b'' where menu_id=43
update ccMenus set menu_descrip = ''Asignación de campaña|Campaign Assignment|Atribuição da campanha'', release =''7172795309f1fa16c6115d56b3c7d287073ff1bbb59eb064560ddb981d7fd730e9a503c9bea8e851be8dc1f09d86bb00d34154ba3507aba98c24da4edbfbf2746464be299792cb6a1680efbc9269b0ab'' where menu_id=44
update ccMenus set menu_descrip = ''Vista de áreas|Areas View|Vista das áreas'', release =''527590c40bfd963f637edd5cc63a0c06d8c90a7c0ae56c436a5a5e0ddc3915eefa1d8c8c2f222061e4b3e2d95808e55b'' where menu_id=45
update ccMenus set menu_descrip = ''Vista de grupos de trabajo|Workgroups View|Vista dos grupos de trabalho'', release =''de2919ca4d64fb1651f0b15aa8e0e28b6e74c1d7b377bbc2501de2e77cd0afbaac2b1e3280301fc449223d8f2dd7eac9edb410c6c0706a6746f8463d77873e9d021c4c5e486425fe61ee1d8993ed6909'' where menu_id=46
update ccMenus set menu_descrip = ''Vista|View|Vista'', release =''51130c9265f4fa7dee6ce1f832082d9f4fd2e9de9e78330d066566e42b733b94'' where menu_id=47
update ccMenus set menu_descrip = ''Asignación de calificación|Disposition Assignment|Atribuição da classificação'', release =''0136b908696acb11b0399e25cff6f54ec76f668f15be3da0422c589b94a1ab2e77da6f20b7a3c0cdbac484df09f78db3f0a75419785483823dbac46ab1a13cf18885ba2e5e585be31e7999e9ea2cef4e995af2df65334484351b7d03f253581f'' where menu_id=48
update ccMenus set menu_descrip = ''Permisos de administrador|Administrator Permissions|Autorizações do administrador'', release =''e7444bff31cf8690971a3765fd7be8856ac97e7b828c495c5b07f01ce535ab57c3c8d530156cc144b0d3507762c27b2053aa5e69dbd5f29b63e31de76849880710638c9ac3866c4148cc79290ac7c97e75e172490033ecfb785b21f1fb455b10'' where menu_id=49
update ccMenus set menu_descrip = ''Gestión de grupos de mi área|My Area Workgroups Management|Gestão dos grupos da minha área'', release =''8a54b89d53297e7871a0c4072a3de33a36f98b8e6efa1fcd54f21e3f16c41fe89f366c4101b513b5d80b7c02fdc2e94e39d8e979981b07e72f5c0ccf2d954cc79748ea4916e7dcee9a51768ca4344000c62cbe10ba5440e42d065b73eb9b0baf'' where menu_id=50
update ccMenus set menu_descrip = ''Historial de chat |Chat Log |Histórico da conversa'', release =''b14dfaa33570212ebf08ddc649b950b525d412c2306804d77af36e167f5a9e618e14f8da9b79f16365ce7836ca06eb7ca52770b4d7cb68ddd4cd39546265f10e'' where menu_id=51
update ccMenus set menu_descrip = ''Asociación de campaña|Campaign Association|Associação da campanha'', release =''7202fae50d36c63c3e4cbb3bb409e489085477320ab8f171532bebb3ec1d1104c79e3433aa43bf3fa37065e1bf771b73ab137030427c59bed0475689d4f476ed517a7328fa8a82f728fc80b49f44d2d9'' where menu_id=52
update ccMenus set menu_descrip = ''Tipos no disponible por administrador|Unavailable by Administrator|Tipos de não disponível por administrador'', release =''ffcfecd78fa179024db85f3e3a359f8c9e9b9b5efdd743bc9006cf139b3fc7cdbaf644f68e31fcc4d9a916554bccbbda26ac9dd8ce595871ce8b98b96774f21706d46aea68e0070151405d93948982440344defb74d9024e4a092af104d36cb1ed4dcee7fd334cc76a4973396457d14f'' where menu_id=53
update ccMenus set menu_descrip = ''Mensajes de audio|Automatic Messages|Mensagens automáticas'', release =''c7439dca463672a2f50dc0d2f578859ae81f5b2245ba654ab4f3617b1956cde062942a22a5dc12bcc8e3c199bd7bbab7f27ab2a9227e1bafc4f492972d4dcb26'' where menu_id=54
update ccMenus set menu_descrip = ''Números de transferencia|Transfer Directory|Números de transferência'', release =''9b3d10c34e016fa606c8503329315c02ca3038b855baeac7761b4570cf3ebaa879559722f6127d390a8ea4847d8df760b2e5c0f47dcc02c6d6284b3a9cd3943c5b77d258c3a29c4813e0e950e82a7c91'' where menu_id=55
update ccMenus set menu_descrip = ''Configuración de buzón de voz|Voicemail Configuration|Configuração de correio de voz'', release =''9f54271c454bdc582cee3c666e3f98e103c54f0483feb0bad0e947c1c2133354db6dea4a4afafbe122f15ca4d69960f387dd5613f01c3cbd2e2d2c46d98e39b20743e5173d97492087aa43068d11fbf66fd73c670e758e82f8fd962e3cb25f36'' where menu_id=56
update ccMenus set menu_descrip = ''Configuración de callbacks|Callbacks Configuration|Configuração dos retornos de chamada'', release =''ec7b3d37a7c244aa749664387d2ad4bf504fb7de7b4115e7803b2ac84e09a7cd7669b8938f063fa1bf2bd342773033fea1b60c16e9253c4b183a3d21836e16b5a05fde05e678b727fca3a7f35dbb3e89417bbac66f25491e304b7b69ce8f7bd7'' where menu_id=57
update ccMenus set menu_descrip = ''Llamadas por agente|Calls per Agent|Chamadas por agente'', release =''95f092f5890652ffac6e3fdb26b40cf6eb3437a8bb265520dde05f5747937ac9d4ce244bf4ad0425c788bc04119a679e3a540d0260060bd139b2acd226bdaa35'' where menu_id=58
update ccMenus set menu_descrip = ''Configuración de vistas|View Configuration|Configuração de vistas'', release =''9f54271c454bdc582cee3c666e3f98e11776165c80cc437046384e056ab4ed370576d72dfb497c189eed5f050e3af4b1dca2feea8e4193b235f30b1e324aeef71f496716758fab448fd144d97cf43525'' where menu_id=59
update ccMenus set menu_descrip = ''Ayuda|Help|Ajuda'', release =''4c31a7721d5dc190baccbd1d0dac84f0f72bf971c2f8f793e3b3962f882f63d4'' where menu_id=60
update ccMenus set menu_descrip = ''Temas de ayuda|Help Contents|Temas de ajuda'', release =''afc997e7761f14f12b57430761bfff30f7ceb14692d92363b05ef42cb9ff882145329cae1fbdaa5d6c01986433ba3920'' where menu_id=61
update ccMenus set menu_descrip = ''Asignación de grupo ACD|ACD Group Assignment|Atribuição de grupo ACD'', release =''0136b908696acb11b0399e25cff6f54eece46ae72f4917c62756999e53b367715efc5b3cb46d3e174dd10c5a75535a8437d2324c181f04dd630e0efac5b40acf7a724f6ffcf2be7093c0600b3b57dcde'' where menu_id=62
update ccMenus set menu_descrip = ''Números ANI por clave lada|Local ANI|Números ANI por código de área'', release =''1471b681995a8c35ec8397a536ec36bbfa3eb650dca35ca0afbdb7edba59c10d96aa758572f56ebd0d05089f4f86253c94767f49fee990722ea86b579c44ddcf40ff276be48defe67b55ef19469ffdb4'' where menu_id=63
update ccMenus set menu_descrip = ''Administradores conectados|Administrators Online|Administradores ligados'', release =''67f0e4ac0a6b9b86ea70c212ebc1fdf38e5d88c818d02affc9fe5662db0e42d1faf3c4942671970f64dcded61429bf5be8f8c356618027bbf94c8d1ee26d9fd0c84330ed992f35de96fcdcf975fe22e3'' where menu_id=64
update ccMenus set menu_descrip = ''Gestión de roles|Management Profiles|Gestão de perfiles'', release =''13d2f0a6b06bbb6cb5b3c59a6cae341c04ac1da0222d1191e0ffe0815cff26f69199e618085f43cb6a20b978a118cd8d79d6561ba033b7acc7308dd7a052a6cf'' where menu_id=65
update ccMenus set menu_descrip = ''Monitor de puertos|Dialer Ports Monitor|Monitor de portas'', release =''9dce99cc0370199e66b7c5e0e371d343bf0a2e3af7036d84a693b9fbf923a3f74c1d18d0888fa9a5955017b23f0cab2a061338ef3b5d19dd459993afa7ca10e9'' where menu_id=69
update ccMenus set menu_descrip = ''Asociación de encuesta|Survey Association|Associação de pesquisa'', release =''7202fae50d36c63c3e4cbb3bb409e489b8041a66c81b61b518f83368e18cfc3e2067ec98f4e43c10620a4ea8a31051d757b7034479ba31b0296785ef0950dde5ca6e2a35abd986f1aeae305736a2ef04'' where menu_id=70
update ccMenus set menu_descrip = ''IVR|IVR|URA'', release =''9e119720d1ac0118df71514181680a89'' where menu_id=71
update ccMenus set menu_descrip = ''Guion de agentes|Scripting|Roteiro dos agentes'', release =''a26d005201984b33e3469edeba7ac5a9b117979f3b67e9cc8ed5dc5b7721af80d4ea5c822f0b50d2683bc4294ba2ef0b'' where menu_id=72
update ccMenus set menu_descrip = ''Grabadora|Recorder|Gravadora'', release =''e286fc4ffbbcb5084d6cc222d60567f62263b822c9830437333a925885ec25a5'' where menu_id=73
update ccMenus set menu_descrip = ''Formatos de evaluación|Scoring Templates|Formatos de avaliação'', release =''54c093e373302ff86aece5040cc4de2b25b4a9b98de8b775f93b91cd599398bbd0d680031cc386cbea5df4e060dad40e474f1353cb80702796d4acfdf4068d1abb9d3ea9a786f563beaf8a02705e6074'' where menu_id=74
update ccMenus set menu_descrip = ''Perfiles de exportación|Export Profiles|Perfiles de exportação'', release =''79ed371512e649e77dd10fa99c7d904acaa304b371a9d374797d1dfce44500d7f8b6e9513000b0c13b91a3b99924d09f0ea04fd82c39e31bafbe4ee258f4810d24c29afb04e81b491256bcb333066015'' where menu_id=75
update ccMenus set menu_descrip = ''Configuración de AVRS|AVRS Configuration|Configuração de AVRS'', release =''9f54271c454bdc582cee3c666e3f98e12009688903015cfbe334af813fc6c7ce811c3d35510157854e2a6374334a803b426a6edb8b69c876509a49ea5b9feb942ef64c04ed8bb216adb46062ee5d335a'' where menu_id=76
update ccMenus set menu_descrip = ''Configurar No Disponibles por Campaña|Configure Not Available by  Campaigns|Configurar não disponíveis por campanha'', release =''ed93be8757f2d065ba8e1da0137bc1e7eb912738d52ec64ebf960dc06697dd9f58b831d628813db6953c3e59337e20d7cfcd07d03b9623aed3d1b03c3e3baef45746fa3b4e838d7666ba1d0415b671b7d58bb6ab8680fc173b971d853cb3ebe07def06375e5ace9ee3e6b348b72a04e6f5311c42f7560e1c484454cacaf63adf'' where menu_id=77
update ccMenus set menu_descrip = ''Configurar No Disponibles por Grupo ACD|Configure Not Available by  ACD Group|Configurar não disponíveis por grupo ACD'', release =''56ac1ed791ca894d238dc1349280b5a1e2c5c7ccc83038a562725f7f72942c73f39b384757526e186e0bec1e991c7b9d70449b38ddbd01b27113b1ef75edd101e041ee08db64ef589d5ad57fed82714d6969ba532785fe41f9db04e379ce46a01913e089bf9eda5f7c0970a72ab617637b9f39b90b58d49b83058a5dc025db1c'' where menu_id=78
update ccMenus set menu_descrip = ''Plantillas de multimedios|Multichannel Templates|Modelo de multimídia'', release =''fec74cbaf0b2d7132ee780dabe49895080099c393ebceefb3f21a3efb74960106857e5d4c2ffacf5aced54935e6ee3c5755f46c22c2d2a3e46ea102ad63b3bdf3a86c0c279ffeacfcd79f3ab2f110213'' where menu_id=79
update ccMenus set menu_descrip = ''Medios unificados|Unified Media|Meios unificados'', release =''6776bac546a32695e551cc6053276fecf54e1307ffa6d723ad6534933ae7aa7485bac1ee690bade8fd4b94e9c528acadf5daebd954e8482e30bea445b3ffb13e'' where menu_id=80
update ccMenus set menu_descrip = ''Cuentas de salida|From Email Addresses|Contas de saída'', release =''dbc8236e42a707b69957a1961fb04ab814ab0f803509bd8ee1cb1ce4ce53b909d7587c6b5760b439f50a9055a61ab6773c0515f79ccc10e0ff7e1baea1087240'' where menu_id=81
update ccMenus set menu_descrip = ''Asociación de cuentas de salida|From Email Addresses Association|Associação de contas de saída'', release =''560ed80e1b20ea34c6507d730c5bf457f1fed7bc7dd97e37ebfd050781c6ec5086d0b6eec2aa79bf1194ad3818fa19d8ebb4c5def239352b188702be9f9ae82ce10146d07e7db74543069fa3012b5cd49d27510d3b18c0fece33823151c718e3f6b88a0a1e97af5d0c52c72c5169b379'' where menu_id=82
update ccMenus set menu_descrip = ''CRM|CRM|CRM'', release =''625b8171685423f8bc8f251428140de7'' where menu_id=83
update ccMenus set menu_descrip = ''Firmas de correo|Email Signatures|Assinaturas do correio'', release =''4ac1b8688d4d698a233e8ed87fdb403731fc1fa748d926ce076376f74dc78202979ba97d3fc0d48c9691d83e36d631878d50d8bd9779b58a27dfa6d20ba5e53f'' where menu_id=84
update ccMenus set menu_descrip = ''Direcciones CC y CCO|CC & BCC Email Addresses|Contas CC y CCO'', release =''09cbbffafe26e97542fa49002c1ec5e68ba515f9cbd9bbc03c547910ac6d73ecbb772ab8e40a5722c12ff6e1accc9a9c8a1d62409a465aa3c5a4a747a393624a'' where menu_id=85
update ccMenus set menu_descrip = ''Encuestas|Surveys|Pesquisas'', release =''51d79747960460b9359fc88c227e8e0b6622db66796319bc96db9d64d4842efe'' where menu_id=86
update ccMenus set menu_descrip = ''Archivo|File|Arquivo'', release ='''' where menu_id=1000
update ccMenus set menu_descrip = ''Archivo|File|Arquivo'', release ='''' where menu_id=1000
update ccMenus set menu_descrip = ''Supervisor Grupos|Supervisor Groups|Grupos de supervisor'', release ='''' where menu_id=1010
update ccMenus set menu_descrip = ''Grupos de supervisor|Supervisor Groups|Grupos de supervisor'', release ='''' where menu_id=1020
update ccMenus set menu_descrip = ''Agentes|Agents|Agentes'', release =''96d529790ccfca0b873be2921b21fc8e29052337e780f8f4ba21610cf5811559'' where menu_id=2000
update ccMenus set menu_descrip = ''Agentes|Agents|Agentes'', release =''96d529790ccfca0b873be2921b21fc8e29052337e780f8f4ba21610cf5811559'' where menu_id=2000
update ccMenus set menu_descrip = ''Llamadas|Calls|Chamadas'', release ='''' where menu_id=2010
update ccMenus set menu_descrip = ''Información General|General Information|Informação geral'', release =''c706077b228a003efcba36c3d76f8ccd02311f94c169f3d90625bfe06452ddf3cac31d8ffa0df3127cc5d52da4af7b6018075e84d8cfffce91f142e5847b1865'' where menu_id=2010
update ccMenus set menu_descrip = ''Tiempos|Times|Tempos '', release ='''' where menu_id=2020
update ccMenus set menu_descrip = ''Sesiones|Sessions|Sessões'', release =''3cfc9a33dc5200222201e875d19251c9a4e341cc759be3a1582a4451c287e301'' where menu_id=2020
update ccMenus set menu_descrip = ''Resultados por agente|Results by Agent|Resultados por agente'', release ='''' where menu_id=2030
update ccMenus set menu_descrip = ''No Disponible|Unavailable|Não disponível'', release =''a9f0cd825f8c38e2204fe4850277c64900c3221fbcc50946e9922b3c1ad7d08f47feefa242dfe1d06488e23a0bf2f2c1'' where menu_id=2030
update ccMenus set menu_descrip = ''Sesiones|Sessions|Sessões'', release ='''' where menu_id=2040
update ccMenus set menu_descrip = ''Detalle de no disponible|Unavailable Detail|Detalhe de não disponível'', release =''8ef05a0599ad8a0ad4bcace93d3da032f50b53ac2086c961607a3085ad1a03cce1f79418fac2e8e280e89f19b7c45a840dfaa586dc7cbf1d790695f4931b6209b79716ee0032dc5d6b64c847a48a0a91'' where menu_id=2040
update ccMenus set menu_descrip = ''No disponible|Unavailable|Não disponível '', release ='''' where menu_id=2050
update ccMenus set menu_descrip = ''Reporte KPI Agentes|KPI Agents Report|KPI'', release =''0f10d0f3975fea415f64116b08b3f0f4158b1a1c1255a581f66da60fdbb9f922113ca746523d66b5648e9a3c58a1d42e'' where menu_id=2050
update ccMenus set menu_descrip = ''Detalle de no disponible|Unavailable Detail|Detalhe de não disponível '', release ='''' where menu_id=2060
update ccMenus set menu_descrip = ''Sesiones por intervalo|Sessions by Interval|Sessões por intervalo'', release =''9032ee7929290765e01291a25dca0a7052d8521c779ad007529a9f3a46064079ecaa16317b4e1b6866f180f35068fae1e323d901476258d5cf14b979c685eb708dda6d4aa90960d36cc08f0eec25de47'' where menu_id=2060
update ccMenus set menu_descrip = ''Productividad|Productivity|Produtividade'', release ='''' where menu_id=2070
update ccMenus set menu_descrip = ''Estados de agente y llamadas por intervalo|Agent and Call Statuses By Interval|Estados de agente y chamadas por intervalo'', release =''9845b8194326d000bbf125cc69f93b76c97e97d0bdd431f0e04d5b455413f8fa1c2f669901ecb5f36e912e128c22c6773da345481c0c9c50286221101986c4c4b2f637f3e469b15dd8dca1fca72b0b33effc8a7ec6a390d56e3661aad87a86541fe5835dcfd03097a45e211d54b7c764cfa1bc6b055ac57048e7620bb67874bb'' where menu_id=2070
update ccMenus set menu_descrip = ''Reporte KPI Agentes|KPI Agents Report|KPI'', release ='''' where menu_id=2080
update ccMenus set menu_descrip = ''Detalle de agente por día|Agent Detail by Day|Detalhes de agente por dia'', release =''eefae185aa125f584d532e0f80546a1fef657d9b4f60d1d23e66b78ef93ded3a0c9d78f2b1ec9493136e6cdae061236cd802dd829354714d6074516bd3071ca3ca98220ae6f34b048c95d3a2be3f4a07'' where menu_id=2080
update ccMenus set menu_descrip = ''Grupos ACD|ACD Groups|Grupos ACD'', release ='''' where menu_id=3000
update ccMenus set menu_descrip = ''Especialidades|ACD Groups|Grupos ACD (especialidades)'', release =''92abc655568830781f4b86ee96a0d715bc7b6de95bbba6857b5a50593315cb6b69ad6c5e064fc38ac64103c6f6e73aa106a0576d5a5ae3754a6c5b9659db87d2'' where menu_id=3000
update ccMenus set menu_descrip = ''Detalle de Llamadas|Call Detail|Detalhe das chamadas'', release ='''' where menu_id=3010
update ccMenus set menu_descrip = ''Detalle de Llamadas|Call Detail|Detalhe das chamadas'', release =''88671a67a73c950bc8e1af9f0e227c0f0f64ff6cac783bf28d06ea68775a3a2715e6ca4c9a6d332f97f716a6f1ee17b5b2cfd87b190990222d62ce83afad2291'' where menu_id=3010
update ccMenus set menu_descrip = ''Llamadas general|Answered Calls|Chamadas geral'', release ='''' where menu_id=3020
update ccMenus set menu_descrip = ''Llamadas por  Grupo ACD/DID/general/WG/Area|Calls by ACD Group DID general WG Area|Chamadas por grupo ACD/DID/geral/WG/área'', release =''21c9167ed1f5346df3fc24bba193f68ae416e2b354ac1d6b9a0d37f767bff137e9d50f8c83b49b621ce8c838d72691f6b96a3dfe005e14c988bca7dff7701e52d3db66aa10a4497cbaf146a90013984b06de7e8eef68f79c795442e002c42466ab0f5b5f5f290f98c7f802c9a901e06fb891f8210d3483124dff843e920206f3'' where menu_id=3020
update ccMenus set menu_descrip = ''Llamadas por Grupo ACD|Calls by ACD Group|Chamadas por grupo ACD'', release ='''' where menu_id=3030
update ccMenus set menu_descrip = ''No Transferidas por Grupo ACD/general/WG/Area|Not Transferred by ACD Group general WG Area|Não transferidas por grupo ACD/geral/WG/área'', release =''897d365fe1309008528b223040d8fe68a655baad738599eec65bbd1b356120277764e76105b7eaa3086a4bd94ac203e07e5b08622dfd73cc34f59ab20d2edd0054bc598b21fd8b0237421b5021030032e13b1804b45fbb24bfefa2ba1ac865deea7b44aba18adf47d97e4858e19bb39493d29bf3dfd70826ebad4ab41e25c252cae1087d8d0438f47f3ffdd94018e7af'' where menu_id=3030
update ccMenus set menu_descrip = ''Llamadas por DID|Calls by DID|Chamadas por DID'', release ='''' where menu_id=3040
update ccMenus set menu_descrip = ''Calificaciones por Grupo ACD/general/WG/Area|Call Disposition by ACD Group general WG Area|Classificações por grupo ACD/geral/WG/área'', release =''54d108e6439d9428e2b8fd3e9f91fdee51be0db6cdc332bb21353a33b0290c23502ba00ff62717982e9b50dd734050d12501c9effbe49383f5cfa2bced65191db6ea50452c9fd86b085b43b637647fca3724ab0ed4f8f1106251468954ed23acc66469923c5846ee2f514984f1a8e5a991d7f4e63651095fb155eefa6a9fc1a0387a3d51c3fef0158b38a002b0a8261c'' where menu_id=3040
update ccMenus set menu_descrip = ''Llamadas no trasferidas|Not Transferred calls|Chamadas não transferidas'', release ='''' where menu_id=3050
update ccMenus set menu_descrip = ''No trasferidas por Grupo ACD|Not Transferred by ACD Group|Não transferidas por grupo ACD'', release ='''' where menu_id=3060
update ccMenus set menu_descrip = ''Efectividad|Effectiveness|Efetividade'', release =''dfe863a9b40b5e3e799358a093aa026a5b30be48f5b0adf81d507a3c3d2e94c44e5004a8f6875f2d8989c78d90c75496'' where menu_id=3060
update ccMenus set menu_descrip = ''Calificación|Call Disposition|Classificação '', release ='''' where menu_id=3070
update ccMenus set menu_descrip = ''Tendencia de flujo|Change flow|Tendência do fluxo'', release =''618eb9b6a71e84267143b7cedc82d1964ff1c1127f25547f8d2ffc613dbec777dfac1c7875a0f6caa021543657ed368790b8cb89d64bdf1d04c2c88e47f2114c'' where menu_id=3070
update ccMenus set menu_descrip = ''Tiempos|Times|Tempos'', release ='''' where menu_id=3080
update ccMenus set menu_descrip = ''Costo 01 900|Billing 01 900|Custo 01 900'', release =''7a173c9014c92a563fd31045490c1b7d057a1e6dceee6b0479d9165dc39fb19920a20ef212c172db45b095a4148b8ec5'' where menu_id=3080
update ccMenus set menu_descrip = ''Abandonadas|Abandoned|Abandonadas'', release ='''' where menu_id=3081
update ccMenus set menu_descrip = ''Contestadas|Answered|Atendidas'', release ='''' where menu_id=3082
update ccMenus set menu_descrip = ''Efectividad|Effectiveness|Efetividade'', release ='''' where menu_id=3090
update ccMenus set menu_descrip = ''Indicadores clave de ejecución|Key Indicators of Implementation|Indicadores de desempenho fundamental'', release ='''' where menu_id=3100
update ccMenus set menu_descrip = ''Resumen por DID|Resume per DID|Resumo por DID'', release =''70b4a3d32ba74c0e7cf258a505a2a87f75ebc1d90789d54b9326ad55ca03262464e75ad8daa67181ca8b9bb749e5a3f6'' where menu_id=3100
update ccMenus set menu_descrip = ''Tendencia de flujo|Change flow|Tendência do fluxo'', release ='''' where menu_id=3110
update ccMenus set menu_descrip = ''Llamadas Rechazadas|Rejected Calls|Chamadas rejeitadas'', release =''ee6c372bb76697296ddf9c822cf0f0413a909d990e67e9cd23d0b816182cde7dd58bb6fe4e553d40bf744870e5c43f4fb2d4bd34459c2acf70686eeadb5e8a31'' where menu_id=3110
update ccMenus set menu_descrip = ''Costo  01 900|01 900 Billing|Custo 01 900'', release ='''' where menu_id=3120
update ccMenus set menu_descrip = ''Sub Calificaciones|Call SubDisposition|Subclassificações'', release =''1daa38c5c8f28a1aa8d4d98293b41be12544c5b63f7ebc0b0adde3906df6ce78769a1799fabf6c8d7448000c9d25819cfc836798ef07fd45442298fdee6039d4'' where menu_id=3120
update ccMenus set menu_descrip = ''Simposio|Symposium|Simpósio'', release ='''' where menu_id=3130
update ccMenus set menu_descrip = ''Chats|Chats|Conversas'', release =''411bb42a33878ef5788fd252289ccec24256f2bcdb576b30052c92c4a1ab4949'' where menu_id=3130
update ccMenus set menu_descrip = ''Chats por ACD|ACD Chats|Conversas por ACD'', release =''0d736f3481c6d1c942da49622f98db98b1a6387d4e26b1071e5ae8c9209a7a7fefdd8aa06e349ce320c475331c3527f2'' where menu_id=3131
update ccMenus set menu_descrip = ''Chats No Contactados|Chats Not Contacted|Conversas não contatadas'', release =''56512fc2d7e0fd5f73a9fef24d21dd082991c459a9c36412d6afbc19342975723476aa870ff6c646f61f17fa98b414dbb455fdebe8e3ef62b6c2d8ff0312ea2161b5cb38ed82267a6d76c0084ffa439b'' where menu_id=3132
update ccMenus set menu_descrip = ''Detalle de chats|Chats Detail|Detalhe de chats'', release =''00a720a507936015857fbeee4942e7423631f6eb4216c102ede2d5ac6d8153f2e3a09f778420905858df8fefdda76f6f'' where menu_id=3133
update ccMenus set menu_descrip = ''Tiempo Promedio de Respuesta|Average Answer Time|Tempo médio de resposta'', release =''f20593a343b0b62c599e778fade2f79607a5a9ba8ea0c6e26c9a0cbe96f52a292aa2b5dd5a94f53d94a02de4b5b83b48110bb080b86a2a9df613a926aa09dfc0d4e14096aa093a1bc5b94af2f41708e1'' where menu_id=3134
update ccMenus set menu_descrip = ''Efectividad de Chats|Chats Effectiveness|Efetividade (das conversas)'', release =''eca6fbbc13298872edb507549bcd07d81bab739c9ac50a154667ed4439e77f751b757d8c280d0b21ba1d5ad7e0ccda9d6d549319f01ea94520b5128a9c848ce2b578b44e2b564666a12a5ef918e8cfd0'' where menu_id=3135
update ccMenus set menu_descrip = ''General Llamadas y Chats|General Calls and Chats|Geral chamadas e conversas'', release =''9c0ebebe2827fef16c1a39c19a25b6abbd4b09dd91e3d384afe10f7f02c1ee7ef242e45b0e4ebfaf8f59e6fc854a6f213b3e3afc6f41b68a352ce3a61bdb59a8e2767c0673abd80694eb208f10e3e233'' where menu_id=3136
update ccMenus set menu_descrip = ''Resumen por DID|Resume per DID|Resumo por DID'', release ='''' where menu_id=3140
update ccMenus set menu_descrip = ''Tiempos|Times|Tempos'', release =''25ac34eed3d59590b21809e3d65e9df1a9db31f65f162834376876a301b2da93'' where menu_id=3140
update ccMenus set menu_descrip = ''Abandonadas|Abandoned|Abandonadas'', release =''7657fe7b3c16fd849a1b96da2b3a1ab46cd57f40030ab16248f6d63306097f1788a709648bbb2c62639ac65058de3974'' where menu_id=3141
update ccMenus set menu_descrip = ''Contestadas|Answered|Atendidas'', release =''58d4dc99cd15d638724baa23ced7904a2bb1ef7c75d541b4b0f6c0bdd56413de'' where menu_id=3142
update ccMenus set menu_descrip = ''Llamadas por grupo de trabajo|Calls per WorkGroup|Chamadas por grupo de trabalho'', release ='''' where menu_id=3150
update ccMenus set menu_descrip = ''Llamadas no transferidas por grupo de trabajo|Not transferred calls by WorkGroup|Chamadas não transferidas por grupo de trabalho'', release ='''' where menu_id=3160
update ccMenus set menu_descrip = ''Calificaciones por grupo de trabajo|Call Disposition by WorkGroup|Classificações por grupo de trabalho'', release ='''' where menu_id=3170
update ccMenus set menu_descrip = ''Llamadas por área|Calls per Area|Chamadas por área'', release ='''' where menu_id=3180
update ccMenus set menu_descrip = ''Llamadas no transferidas por área|Not transferred calls by Area|Chamadas não transferidas por área'', release ='''' where menu_id=3190
update ccMenus set menu_descrip = ''Calificaciones por área|Call Disposition by Area|Classificações por área'', release ='''' where menu_id=3200
update ccMenus set menu_descrip = ''Llamadas Rechazadas|Rejected Calls|Chamadas rejeitadas'', release ='''' where menu_id=3210
update ccMenus set menu_descrip = ''Sub Calificaciones|Call SubDisposition|Subclassificações'', release ='''' where menu_id=3220
update ccMenus set menu_descrip = ''Campaña|Campaign|Campanhas'', release ='''' where menu_id=4000
update ccMenus set menu_descrip = ''Campaña|CampaignM|Campanhas'', release =''3df6b7dc4342106773d35c9daa327d124da0ed72853308384b60cd72f3eb137b'' where menu_id=4000
update ccMenus set menu_descrip = ''Detalle de Marcación|Dialing Detail|Detalhe da discagem'', release ='''' where menu_id=4010
update ccMenus set menu_descrip = ''Detalle de Marcación|Dialing Detail|Detalhe da discagem'', release =''94b6faad25978826165a3650f2ac52419cacff55c626eba9a6f167d6c3aa4438740080d4c560bf5fdfc0c5e8187d0bc8e249f4ae867febc77be3efbf943dc3f6'' where menu_id=4010
update ccMenus set menu_descrip = ''Detalle de Llamadas Cont.|Answered Calls Detail|Detalhe das chamadas atendidas'', release ='''' where menu_id=4020
update ccMenus set menu_descrip = ''Detalle de llamadas Cont.|Answered Calls Detail|Detalhe das chamadas atendidas'', release =''6e47659dcaf4473cf1414f28c8c3e5963ba40799a1b493c45118651d66980d3828b2b1d7a4ac8717cf9dfb7f558fc615df865b0a811d0af3400471e0773632d9110ed0d9ae97c8def167b147c486d89b'' where menu_id=4020
update ccMenus set menu_descrip = ''Llamadas general|Answered Calls|Chamadas geral '', release ='''' where menu_id=4030
update ccMenus set menu_descrip = ''Llamadas contestadas por Campaña/general/wg/area|Answered Calls by Campaign general wg area|Chamadas atendidas por campanha/geral/WG/área'', release =''7f9603c7b03b294b1e3bf597edce2c52a3a156b41984b36ce220d2d6f14a4e6cba260d0ee5cd64e8f7cbbe8723f222de003b4de0d4da1f61e64cf69f04dc0078145d9d7a567fe68c20747b39f2d45d70d68a79da963f7163c08f5d1e10296f954eed55fe4222b597b03b82275e0690f0bbaf8a62986df944a34c16377c77fc9541511a81680ae11622b9ba80e5805269'' where menu_id=4030
update ccMenus set menu_descrip = ''Llamadas por campaña|Answered Calls by Campaign|Chamadas por campanha'', release ='''' where menu_id=4040
update ccMenus set menu_descrip = ''Calificaciones por campaña/wg/area|Call Disposition campaign wg area|Classificações por campanha /WG/área'', release =''86ce8cbbe658db12522d483d082a8c7db5ee2873b0449dc419dfbdaafbacc0727f341365a711302b884f3cf3fcb3a7e79783ce0e8ce937d7db9bca8d4ee1acaf8f12ab292797a39975474136388885092ae85a5b0597a5e368bb9d145b84e8ab1b6d05f2c42fa2717d85979ef27a4cbb'' where menu_id=4040
update ccMenus set menu_descrip = ''Calificaciones|Call Disposition|Classificações'', release ='''' where menu_id=4050
update ccMenus set menu_descrip = ''Marcación por Campaña/wg/area|Dialing by Campaign wg area|Discagem por campanha /WG/área'', release =''ded69caddd3292663d1c288191974f77c293acdf7c0eeb41a99acab089a41cb26aa6f528788f3d3ef2a622c8051e74130d27bcd3bee0d220ea20e3bf4bf971ad215da7f73fcf38ac25c4c0d6d494c4d276a960fdea3812e00f21c38c1ad063d6'' where menu_id=4050
update ccMenus set menu_descrip = ''Marcación por campaña|Dialing by Campaign|Discagem por campanha'', release ='''' where menu_id=4060
update ccMenus set menu_descrip = ''Costos|Call Billing|Custos'', release =''1bd5c741650fc4f3a194486d99c23fbd1f7517fd64793f7001c9f10920509561'' where menu_id=4060
update ccMenus set menu_descrip = ''Costos|Call Billing|Custos '', release ='''' where menu_id=4070
update ccMenus set menu_descrip = ''Llamadas Contestadas por número de teléfono|Answered Calls per telephone number|Chamadas atendidas por número de telefone'', release =''fc0c387ebf579858b90c4f8f53fcf825576d14c6f239bb8ac507c6cee889596dd6da97c7c41a55f086cd327f6352519aa0f24ae7ea6a838163164b52a76be8297d10c6bb433680fe30dd4e1484efbfe9943c99dd11f15bf5c0306aabe98e8c28c590eec63c40ff896b641680f8c381f6dc1c518c638f8c7a9e4901ec443c47b3'' where menu_id=4070
update ccMenus set menu_descrip = ''Agente|By Agent|Agente '', release ='''' where menu_id=4071
update ccMenus set menu_descrip = ''Campaña|By Campaign|Campanha'', release ='''' where menu_id=4072
update ccMenus set menu_descrip = ''Proveedor|By Carrier|Prestador'', release ='''' where menu_id=4073
update ccMenus set menu_descrip = ''Llamadas con transferencia|Calls with Transference|Chamadas com transferência'', release ='''' where menu_id=4080
update ccMenus set menu_descrip = ''Teléfonos más marcados|Dialed Telephone Numbers|Telefones mais discados'', release ='''' where menu_id=4090
update ccMenus set menu_descrip = ''Reporte KPI Outbound|KPI Outbound Report|KPI'', release =''086f81cc6471414063117c5fdfbbbea7abd8139d996435dd276bb3745b30fe0d39949faefbd60a581cfa69ca6e5a71be'' where menu_id=4090
update ccMenus set menu_descrip = ''Llamadas por calificación / Estatus (Telmex)|Calls by Disposition/Status (Telmex)|Chamadas por classificação'', release ='''' where menu_id=4100
update ccMenus set menu_descrip = ''Sub Calificaciones|Call SubDisposition|Subclassificações'', release =''f9bd3104348eebb06d7417f73071b96cfe83fcdf8b3183ce992d1515ff619de7fb3a837099f56a14ed299e1e4327aa84bff0ab4f52898e3c4081fd5fb40fef11'' where menu_id=4100
update ccMenus set menu_descrip = ''Llamadas contestadas por estatus|Answered Calls by Status|Chamadas atendidas por estado'', release ='''' where menu_id=4110
update ccMenus set menu_descrip = ''Reprogramación|CallBacks|Reprogramação'', release =''23541c08d5c45c0bbdc418fd3c6d3c97c56656d5f59b5d49410ccb0f79b3e4d1d6ca9b7c48b6c781be1b6176e8f20dbb'' where menu_id=4110
update ccMenus set menu_descrip = ''Llamadas contestadas por grupo de trabajo|Answered Calls per WorkGroup|Chamadas atendidas por grupo de trabalho'', release ='''' where menu_id=4120
update ccMenus set menu_descrip = ''Llamadas con transferencia|Calls with Transference|Chamadas com transferência'', release =''6283c7b8c70a61261c23495ad0d60d0eb6eb57e4ba562cddfcdd69554c841eff563bdad7f660b97fa30e5302b08bc061d32b03a316894d6419c0851278df31aa5a9561b52307ff5ef6c2ee2fbc8a4267'' where menu_id=4120
update ccMenus set menu_descrip = ''Marcaciones por grupo de trabajo|Calls per WorkGroup|Discagem por grupo de trabalho'', release ='''' where menu_id=4130
update ccMenus set menu_descrip = ''Llamadas contestadas por estatus|Answered Calls by Status|Chamadas atendidas por estado'', release =''7f9603c7b03b294b1e3bf597edce2c52f2a3d3635d138a40248da16a757c755d7f23dc5f5f75305799ef8851b1b19c57e2a98576f81a5cf047258572b00e8f181a711a3b0a0eecc09c8282ecc38ac46f9b7788c36a06bbde028d46e772457a10'' where menu_id=4130
update ccMenus set menu_descrip = ''Calificaciones por grupo de trabajo|Call Disposition by WorkGroup|Classificações por grupo de trabalho'', release ='''' where menu_id=4140
update ccMenus set menu_descrip = ''Detalle de llamadas en chat contestadas|Answered Calls On Chat Detail|Detalhe de chamadas atendidas na conversa'', release =''dcb850d9556a21ad8aa2b04cb1c805201d844d742b968ce9571ca24476bcf8c17ab06c58fc2aa71d2f9e182d31a3de899fa680622471fa2e8706e2e4e07f60947e6e087d2d27cdbc1a323e6c86645b90e1d87cd5ecd54c1db1890be8333d1d42ea63bc5d0100a3762e536138913850ff7d72a43e54753e7c5ffb0eb97a9175d3'' where menu_id=4140
update ccMenus set menu_descrip = ''Llamadas contestadas por área|Answered Calls per Area|Chamadas atendidas por área'', release ='''' where menu_id=4150
update ccMenus set menu_descrip = ''Abandono por campaña|Abandoned calls by campaign|Abandono por campanha'', release =''229820a611c3b1d998336cda7aacb07d5a3ca43ae05ace1fddbc6841331cd7ed47dec3af93ff486ce7a5a71bff8c2a56447ee5404bd785a4d98c7f8312b7bb49cd0b32c7014ec846eef3b8d48a6a6298'' where menu_id=4150
update ccMenus set menu_descrip = ''Marcaciones por área|Calls per Area|Discagem por área'', release ='''' where menu_id=4160
update ccMenus set menu_descrip = ''Calificaciones por hora|Dispositions by hour|Classificações por hora'', release =''54d108e6439d9428e2b8fd3e9f91fdee5f952d3162915efc1d9a9ceeb67ab326942234b112191196b5c914b65a207f00f6aa6dbdebd8d344b659128175d57d223b2916893bdac8722a31fa4652f8a98f'' where menu_id=4160
update ccMenus set menu_descrip = ''Calificaciones por área|Call Disposition by Area|Classificações por área'', release ='''' where menu_id=4170
update ccMenus set menu_descrip = ''Gestión de base|Management Base|Gestão de base'', release =''d71e103870d96b6765f2ee439d2af114fb6f5574587bad77cc997e68802daa13b847ae101a8b1f54fc361c570f84f1f16a1cdc51682e6a68d849b71151f31f9d'' where menu_id=4170
update ccMenus set menu_descrip = ''Reporte KPI Outbound|KPI Outbound Report|KPI'', release ='''' where menu_id=4180
update ccMenus set menu_descrip = ''Detalle de resultados de marcación|Dialing Results Detail|Detalhe dos resultados de discagem'', release =''db47a2867c7795a221f61d9e0dccebfb32d8fb3e0026848cfc108c677051317d6f93de038e1f16b80f67b6139265c86edbd6acb60e2bcd72bd294fb6f56fc7a17a91d7ffb04cd54b2d17370cf41d367fb1f6510dbafc6641d783caefe8fa3509'' where menu_id=4180
update ccMenus set menu_descrip = ''Sub Calificaciones|Call SubDisposition|Subclassificações'', release ='''' where menu_id=4190
update ccMenus set menu_descrip = ''Llamadas contestadas por reintentos|Answered Calls by Dialing Retries|Chamadas atendidas por repetição'', release =''7f9603c7b03b294b1e3bf597edce2c5231780fd215b73ce2a47392e356505240828532309bfa5e501bdc0ca946b446e3d47e09947906ed2b769889561b55592ac9bec2c201f18f871f43322ec3802373f421862917e80d0f4200531eef0b392fd6b675ca705c5f8bd4b1cf0d7e9d889e'' where menu_id=4190
update ccMenus set menu_descrip = ''Reprogramación|CallBacks|Reprogramação'', release ='''' where menu_id=4200
update ccMenus set menu_descrip = ''Reporte MLS|MLS Report|MLS|Reporte MLS'', release ='''' where menu_id=4210
update ccMenus set menu_descrip = ''Reporte de números telefónicos por Estado de la República|Telephone Numbers by State Report|Números telefónicos por Estado da República'', release =''94876e9b8b232270fece46d9fc0233a7f810ac1c5ac6c2a03d59c4404e28a0c43ef3618c0e07fd295db613949d5c5b198d0864ea7bffa8db6a6df48e752c93c431b281f4d899c7f057dc963930309126a51089e74aa6d71d9e468f2ef4bbafb26e978ddd59c8647b73fd185d9ea766455cb9ea5dfcebfbba44572bf75b921a24c03b925ceaca67722aae2d3930204399'' where menu_id=4220
update ccMenus set menu_descrip = ''Reporte de números telefónicos por registro/lista|Telephone Numbers by RecordList Report|Números telefónicos por registro'', release =''94876e9b8b232270fece46d9fc0233a7f810ac1c5ac6c2a03d59c4404e28a0c40eaade12674a111dbfba34cfd4a3efd7c09b538de3ae9891c2ed4b98f2e08acd083c26b7666470d365e856c76e59c751db6742a3d712a80e4695b7793470b32e724c8888605cc80f241e45cb1b7ce51b98ea60641de42c61611b5b50177d0983'' where menu_id=4230
update ccMenus set menu_descrip = ''Reporte de resultados de marcación|Dialing Results Report|Resultados da discagem'', release =''9cf7679f1b10838b63e4eae2368159813ae5d3eecaf4bccecfb21a247080897dc3e3d80988c85c0931f5a2fe77da619d4bf315be75f4dfc74e2005e68e462307a1378245a6e1ae89d51c1185abae83e2ce9333393a51416309282c5f4e92f9d5'' where menu_id=4240
update ccMenus set menu_descrip = ''IVR|IVR|URA'', release ='''' where menu_id=6000
update ccMenus set menu_descrip = ''IVR|IVR|URA'', release =''9e119720d1ac0118df71514181680a89'' where menu_id=6000
update ccMenus set menu_descrip = ''Detalle de IVR|IVR Detail|Detalhe da URA'', release ='''' where menu_id=6010
update ccMenus set menu_descrip = ''Detalle de IVR|IVR Detail|Detalhe da URA'', release =''f7adec3242a59f86dc4f3a8072e571943484d3508f1437f69e68a2f58542c37c6d445fdc35f64b627c0bce33dddd08cb'' where menu_id=6010
update ccMenus set menu_descrip = ''IVR General|IVR General|URA geral'', release ='''' where menu_id=6020
update ccMenus set menu_descrip = ''IVR General|IVR General|URA geral'', release =''00a21455609916b202052d466a352b5e2b60640229f768b88ab146fc8dc2cbfcb331aa7e569605ee58eba0a17f269bb0'' where menu_id=6020
update ccMenus set menu_descrip = ''Primera opcion del menu|First optionselected|Primeira opção do menu'', release ='''' where menu_id=6030
update ccMenus set menu_descrip = ''Primera opción del menu|First optionselected|Primeira opção do menu'', release =''9ae737a9afce05eaf5cbbf25e2ba8b3f1a11feb6ade86e49a24cc15d9657765fdc4ba34bbe7aaee445a09fdd80e9971c335f744305475644343279f5e9248a3671ebb6f800198b8b57ae773509311b80'' where menu_id=6030
update ccMenus set menu_descrip = ''Por Opciones|By Options|Por poções'', release ='''' where menu_id=6040
update ccMenus set menu_descrip = ''Por Opciones|By Options|Por poções'', release =''15c4927a18daca287dd9c826d6b1ee7e356b1d1484a375083d9ad05899eb479d49d8f86c730c525c1bec3179fb96ca83'' where menu_id=6040
update ccMenus set menu_descrip = ''Encuestas de IVR|IVR Surveys|Pesquisas de URA'', release =''4624fb0c3f01a4f7ffa2f345efb45a3bddffe290dec7b93248d1f8820f365b75284c69e595aef52578a2efad2aa5d692'' where menu_id=6050
update ccMenus set menu_descrip = ''Especiales|Special|Especiais'', release =''ba0bc68dfaf1522a21afa079a09a3eec3f7e80b2462356bba9d1bf81ed4ff8fe'' where menu_id=7000
update ccMenus set menu_descrip = ''Reportes de abandono|Abandon reports|(Relatórios de) Abandono'', release =''738ebc86f3f41c09dfbc766e6916e79acfba1ff528ff3200df04344760549be158c0dd2f01428ef0881211b2480a5b2edb37bb4111d95494becf7f2419b178e4'' where menu_id=7010
update ccMenus set menu_descrip = ''Resumen por agente|Agent summary|Resumo por agente'', release =''6127bfcd82490ed646b4932d276f186f9ac429af9c4214ff5dbece19d98c750356910ec7d8f50b727f1215cac46f4476f36c55fd039943f3faf95d7893c6a81b'' where menu_id=7020
update ccMenus set menu_descrip = ''Movimientos por campaña|Movements per campaign|Movimentos por campanha'', release =''5d571d4f307b7d64c401eac958f36de9d9d17d1c0743b6712c0ad6b4ec198d95d5c9f5fb8e7bc05c946de5094edfa5293df23929cd1832205ab181d31aa93e9109a7f85eab860e6ae807f6c17da89f1b'' where menu_id=7030
update ccMenus set menu_descrip = ''Promesas por campaña|Promises per campaign|Promessas por campanha'', release =''64a52235cd512a5867e3bf128b595fda6dd523479e736d9a755677146402aca99f35d188002b9555a8c15e26e2ae149071c543bad2227205505fc419a3857ecfd1f0f5f9a9bcba8e54dd04b472008c93'' where menu_id=7040
update ccMenus set menu_descrip = ''Rend. por asesor|Performance per agent|Rendimento por assessor'', release =''c914940aa9fd9c40a06f419be041c7ece815861d64e35df3ade5953c0c3c24a062547314a714b3c85c7abf159c343570c9b3495c95670e0ae1b0c15fc31c5474'' where menu_id=7050
update ccMenus set menu_descrip = ''Historiales de cuenta|Account history|Históricos da conta'', release =''5e6c6d0cc8edcaf5acce272ed069253c8968da51ce51256954e0cd470b03f9f2fbc84c75d50ccc4c2d5e01e19409b90a22f851bbdcee21c7deb13aac93bb650e'' where menu_id=7060
update ccMenus set menu_descrip = ''MKT Agentes|MKT Agents|MKT agentes'', release =''58595a92cd28d166cdc11a451aff268cf1192879fbcf52129a469f93afe27d66ba4b0b8dfe2920db1e795b661535fd5e'' where menu_id=7070
update ccMenus set menu_descrip = ''Reporte de abandono por porcentaje|Abandon report percentage|Abandono por porcentagem'', release =''7698d560a7941b44d0142bf76a8028412670e700436a70dd13928a68aab5b907d245bd4323a9f574bbced8ee8a41d1dca22000f1f27b60121833b28ecd293b12bccaa559650d733f01559d7b11d49e5a04759f20a9db7608dc398180131cb57a'' where menu_id=7090
update ccMenus set menu_descrip = ''Reporte de abandono perfiles|Abandon report profiles|Abandono perfis'', release =''7698d560a7941b44d0142bf76a802841fbcad4eda713dea692bba8a80b515b08803bcdf2e40745e5748ed34625347920cd3741d8ab04c4ad80e714f3dbb32d2e50e1894bbbf2cc6b496b22d265b155d9'' where menu_id=7100
update ccMenus set menu_descrip = ''Reporte de abandono por tiempos|Abandon report times|Abandono por tempos'', release =''7698d560a7941b44d0142bf76a802841e2b848149d7c40f78ec0939cacf7c32c234f8d06eda4c388b93c43f48c0b5ee153cd535b1e632746cb25d4e099c688c8fff68dbf41c72636d75f7d7cac8a852c'' where menu_id=7110
update ccMenus set menu_descrip = ''General|General|Geral'', release ='''' where menu_id=8000
update ccMenus set menu_descrip = ''General|General|Geral'', release =''9069f719716240d7b738cd6f41a60f033a81003c46e5336ffdcfe1ca422d0725'' where menu_id=8000
update ccMenus set menu_descrip = ''Ocupacion de puertos|Trunk`s busy|Ocupação de portas'', release ='''' where menu_id=8010
update ccMenus set menu_descrip = ''Ocupación de puertos|Trunks busy|Ocupação de portas'', release =''0362defe0bc9aa21dbe5cdf084801c440fca0417e154644e0a273fe0ffdd9af5dd882e289d9c276aa68d506629019e569bae1d50631ca53dfe9cf91cce205d1c'' where menu_id=8010
update ccMenus set menu_descrip = ''Ocupacion de puertos outbound|Outbound Trunk`sbusy|Ocupação de portas de saída'', release ='''' where menu_id=8020
update ccMenus set menu_descrip = ''Ocupación de puertos outbound|Outbound Trunks busy|Ocupação de portas de saída'', release =''1ef7d4766eabd1e58b5303a6f2bec7c891973e222c3dcafdb473746ffaef91aca50906345359875907408fb45abd6ea9f3f155e3b3c378efa8da46b7bde5e2cae88531515934e9b04039871053bdc6f65057a03a3ed2411d62d0988932fa0a3e'' where menu_id=8020
update ccMenus set menu_descrip = ''Ocupacion de puertos inbound|Inbound Trunks busy|Ocupação de portas de entrada'', release ='''' where menu_id=8030
update ccMenus set menu_descrip = ''Ocupación de puertos inbound|Inbound Trunks busy|Ocupação de portas de entrada'', release =''0362defe0bc9aa21dbe5cdf084801c44a84362415fc694a1331ec564447b43e2ad1f77912821ad8766fd62bd2aeea59f0c26be106bb03bc2e055fdb4a38ec0212f1e6d90580e05b152b9770b8165c912f7438406e4b7acbf1e0bcc30d90dc975'' where menu_id=8030
update ccMenus set menu_descrip = ''Tiempos Especiales|Special Times|Tempos especiais'', release =''2da7610f9626dc12e7669ac08d4099bcd561d8a5e9e0c7a7264a4197b69de5b668b9433e466370022a7758a5853a7e61b679daeaf94c2f87ff21d1f026b38522'' where menu_id=8040
update ccMenus set menu_descrip = ''Calidad|Quality|Qualidade'', release =''eb381bfd4e3225b43b06919869c9b2ce37de43d7add708657141dd5a102b8880'' where menu_id=8050
update ccMenus set menu_descrip = ''Formatos de calificacion|Scoring Templates|Formatos de avaliação'', release =''098b160e934cbb372399f774ac695b31540b07c0014f952339e6e293f97e24f78c55ab24b3a62b6d146b2b29f9c1d37f21c4cc87e82abf3014c46cf1d0c0926062c37737f98e2bb518beeaf7c03f032e'' where menu_id=8060
update ccMenus set menu_descrip = ''Agente(Formatos de Calificación)|AgentScoringTemplates|Agente'', release =''4c642ea42197239d977bff10e4035aa9378655fe3712106e36b29030abf49d7d0be86734ca07a07f823fcaa4480f57d77b088360ded0d18f137e43fb2f918d34'' where menu_id=8061
update ccMenus set menu_descrip = ''Supervisor(Formatos de Calificación)|SupervisorScoringTemplates|Supervisor'', release =''8b0111b1f10de1ea152007b418c596c856e3c588698f62f6709119ed044f7d27b88d57743cd6226cc6dd3bed3f9b50f681cfaa692139ee0190eb9708015f76b9ccae3a756d9c882a14e41ef2bbf175e5'' where menu_id=8062
update ccMenus set menu_descrip = ''Conceptos(Formatos de Calificación)|SectionsScoringTemplates|Conceptos'', release =''06f8c5bd67dc764b2d58954a5e159a725568801cc8bdd416a07041980d801c019d24990b0cfc41b1d65a16c50cb9ee93069d4ed35e8f820d4770fea4e12b864d993068e10a2003a331a7810d273af9d2'' where menu_id=8063
update ccMenus set menu_descrip = ''Preguntas(Formatos de Calificación)|QuestionsScoringTemplates|Preguntas'', release =''005a270289bb12e09e0a31738ac21f172edf271c421bfb55edc03eca24e56c0215943587b6de7475ca96b06c6ab1c2f98b7f9acaa5f2a394f1cc97b9f44505a4a1fab3c9632f37bcee8a72f500c78fd3'' where menu_id=8064
update ccMenus set menu_descrip = ''Calificaciones(Formatos de Calificación)|DispositionsScoringTemplates|Classificações'', release =''54d108e6439d9428e2b8fd3e9f91fdeef35a8a2cf1c81ac605f355c6c5ed088395115b82ed8c782e42034ee93bf0f95a8a2097109472d35847e3bebe7cbd90bd2a5fc20f0ef1db46aa23b9e4400fa958f9a2461e9302548540583d3ba265643c'' where menu_id=8071
update ccMenus set menu_descrip = ''Detalle(Formatos de Calificación)|DetailScoringTemplates|Detalhe'', release =''119304beb0451b2a19536e41012819a7f75bb2a1ee3af087d714af6f1f001f1a90c4dff93d71654c5580714d6aa9b56f42a464f823725df704b331fb788109bf8c2e08c74637645bd0e0133449c06ed6'' where menu_id=8072
update ccMenus set menu_descrip = ''Encuestas de Satisfaccion|Customer Satisfaction Service|Pesquisas de satisfação'', release =''96bdd3fb8047d75a1e63b64bd4ce72dc64c83960a38a3382a253ab751052edd44f579a4a7929d0feafd1ebbd48d87e33f51f315af48b9e202a76895766c7e2cbb81c37a91033e92bdb8748bd8a9ee15a069e31cf3a32b9fffcfc2866f68b1b87'' where menu_id=8080
update ccMenus set menu_descrip = ''Agente(Encuestas de Satisfacción)|AgentCustomerSatisfactionService|Agente'', release =''481d0fc0c3158788180f9154ef1db2815a9a6ae40380130220db30317904d18f18f5efd9bf439ca1aa6f7b62830ca897aa58110be2452cb3dc8297230520e8dd762dc441f3176342bffc1473274e46b8'' where menu_id=8081
update ccMenus set menu_descrip = ''Preguntas(Encuestas de Satisfacción)|QuestionsCustomerSatisfactionService|Preguntas'', release =''9203d567abe7573f85f9f5c55eec9e1735c2a70b838c90c05e86088e3da7163c98c180c59ae1055b3f81ab66d350134130e91c3b8697de14258accbfa92b061f358997758208013fe1c80d7451d5cd4a6245809625c4d8edcc36675a25992904'' where menu_id=8082
update ccMenus set menu_descrip = ''Calificaciones(Encuestas de Satisfacción)|DispositionsCustomerSatisfactionService|Classificações'', release =''153e6811eec81553748db0c3d4e2f22dcb71ee48e699af23268b31717ac2cebb5ce79d6f82713571404d9404d60c7947b50051fbebcdbbaceb8cff9d1ffc3bcb597e2c0dc067442e011eefdd82b199f103641b5805cb78a27a0838ad21f3f133047b0a31922dfa6808c67f762facc35f'' where menu_id=8083
update ccMenus set menu_descrip = ''Detalle(Encuestas de Satisfacción)|DetailCustomerSatisfactionService|Detalhe'', release =''02547c912615a1e4d6552bab57984ee3702a1fb1e963680cfa7044653de25db417da62f779d55da177e98335f1f4b77af879b89a8db6070fcbd689586dde4d7f95ebde36331440c65de7cf8e77f6a21a'' where menu_id=8084
update ccMenus set menu_descrip = ''CRM|CRM|CRM'', release =''625b8171685423f8bc8f251428140de7'' where menu_id=9000
update ccMenus set menu_descrip = ''General|General|Geral'', release =''7e1d6a08abb01a1b1e5c46c29b2958db35be484cf0ac440a0ea9222d4ccfae1d'' where menu_id=9010
update ccMenus set menu_descrip = ''Correo|Email|Correio'', release =''83e7c9d10760400560a2b43adb07acaea572b196b8cf7724691b369dd05733bb'' where menu_id=10000
update ccMenus set menu_descrip = ''Correo por ACD|Email by ACD|Correio por ACD'', release =''9c6c602297410825b497961460515577238d12b7faf4d9d9384be72e85df4c683484a96e8c2348eacd2fd1d4d9d82d35'' where menu_id=10010
update ccMenus set menu_descrip = ''Correo por agente|Email by Agent|Correio por agente'', release =''47e34a74d238060569df56743ee7a37b70af8b3463c50698d6d105f76caf167a366d3450b6ee4f43adc27cf5e0229914c7c0de1474fca473986884eb1902ca96'' where menu_id=10020
update ccMenus set menu_descrip = ''Detalle de correo|Email Detail|Detalhe de correio'', release =''02e33a8aa5030f2d6c2a78bb678ce5f294142ffa65b64d6708ef84f005c9cf382b585018ae2e2951f5cc5353425bfd27d40003999e358be34eefe895fcbca4da'' where menu_id=10030
update ccMenus set menu_descrip = ''Correo general|Email General|Correio general'', release =''f9309f761b4c90b0bf2c6104c668719ff0671c36f17887ba91a5589bc6489ca805618b8e703582e20dabdd2d26ea1e58'' where menu_id=10040
update ccMenus set menu_descrip = ''Twitter|Twitter|Twitter'', release =''ac7a2fd4c5d63bd0c014419d9d346e0dc8791bbf497047b227d20657dac8d147'' where menu_id=11000
update ccMenus set menu_descrip = ''Twitter por ACD|Twitter ACD|Tweets por ACD'', release =''4edf4b5c9ccded5ad3b146fb67e7e7324b95ea2b64cb0ecf57842d12bd860da5467eca732b7c7206eb935823911acd54'' where menu_id=11010
update ccMenus set menu_descrip = ''Twitter por Agente|Agent Twitter|Tweets por agente'', release =''dadf2054ee027fa4e15a09922211034bf69d8db17659ff8c9dbb1b858ed36ad8b8c201ca22165e64f8bd4b27cd7a46bbbfb382397b6c75074c55ad580866d81c'' where menu_id=11020
update ccMenus set menu_descrip = ''Twitter Detalle|Twitter Detail|Detalhe de tweets'', release =''4356689ad0cefdbd48494873256e95368f54fbbe25f67712b06e843ab9593fcdddfc3a94fb1f6bef458358c9c5ca1a35a4bec84744bcd4ea577123876407621b'' where menu_id=11030
update ccMenus set menu_descrip = ''Twitter General|Twitter General|Twitter general'', release =''7b3fe5284cf4d30e0ca0383fb1c680976e6ed109dc62044baa3b498e5495f223220f3a0dccee333e0f6044cd00832db44d2b7f324ee6cb830d25369c49b982a4'' where menu_id=11040
'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES update ccRIALog_Operation -- Version BD 119.122 -- '
    	set @Sql= 'update ccRIALog_Operation set descripcion = ''AGREGAR|ADD|ADICIONAR'' where operationType=1
update ccRIALog_Operation set descripcion = ''ELIMINAR|DELETE|ELIMINAR'' where operationType=2
update ccRIALog_Operation set descripcion = ''ACTUALIZAR|UPDATE|ATUALIZAR'' where operationType=3
update ccRIALog_Operation set descripcion = ''ÁREAS|AREAS|ÁREAS'' where operationType=4
update ccRIALog_Operation set descripcion = ''INICIAR SESIÓN|LOGIN|CONEXÃO'' where operationType=5
update ccRIALog_Operation set descripcion = ''FINALIZAR SESIÓN|LOGOUT|DESCONEXÃO'' where operationType=6
update ccRIALog_Operation set descripcion = ''SUBIR PENDIENTES|LOAD READY|CARREGAR PENDENTES'' where operationType=7
update ccRIALog_Operation set descripcion = ''RECICLAR CALLBACKS|RECYCLE CALLBACKS|RECICLAR CALLBACKS'' where operationType=8
update ccRIALog_Operation set descripcion = ''INICIAR|START|INICIAR'' where operationType=9
update ccRIALog_Operation set descripcion = ''DETENER|STOP|DETER'' where operationType=10
update ccRIALog_Operation set descripcion = ''CAMBIAR TIPO DE JOB|CHANGE JOB TYPE|ALTERAR O TIPO DE JOB'' where operationType=11
update ccRIALog_Operation set descripcion = ''ELIMINAR PENDIENTES|DELETE READY|ELIMINAR PENDENTES'' where operationType=12
update ccRIALog_Operation set descripcion = ''ELIMINAR NUEVOS|DELETE NEW|ELIMINAR NOVOS'' where operationType=13
update ccRIALog_Operation set descripcion = ''ELIMINAR CALLBACKS|DELETE CALLBACKS|ELIMINAR CALLBACKS '' where operationType=14
update ccRIALog_Operation set descripcion = ''CAMBIAR ORDEN DE MARCACIÓN|CHANGE DIALING ORDER|ALTERAR ORDEM DE DISCAGEM'' where operationType=15
update ccRIALog_Operation set descripcion = ''AGREGAR USUARIO|ADD USER|ADICIONAR USUÁRIO'' where operationType=16
update ccRIALog_Operation set descripcion = ''ELIMINAR USUARIO|DELETE USER|ELIMINAR USUÁRIO'' where operationType=17
update ccRIALog_Operation set descripcion = ''AGREGAR GRUPO DE TRABAJO|ADD WORKGROUP|ADICIONAR GRUPO DE TRABALHO'' where operationType=18
update ccRIALog_Operation set descripcion = ''ELIMINAR GRUPO DE TRABAJO|DELETE WORKGROUP|ELIMINAR GRUPO DE TRABALHO'' where operationType=19
update ccRIALog_Operation set descripcion = ''AGREGAR AGENTE|ADD AGENT|ADICIONAR AGENTE'' where operationType=20
update ccRIALog_Operation set descripcion = ''AGREGAR ADMINISTRADOR|ADD ADMINISTRATOR|ADICIONAR ADMINISTRADOR'' where operationType=21
update ccRIALog_Operation set descripcion = ''ELIMINAR AGENTE|DELETE AGENT|ELIMINAR AGENTE'' where operationType=22
update ccRIALog_Operation set descripcion = ''ELIMINAR ADMINISTRADOR|DELETE ADMINISTRATOR|ELIMINAR ADMINISTRADOR'' where operationType=23
update ccRIALog_Operation set descripcion = ''ACTULIZAR PERMISOS|UPDATE PERMISSIONS|ATUALIZAR PERMISSÕES'' where operationType=24
update ccRIALog_Operation set descripcion = ''AGREGAR CAMPAÑA|ADD CAMPAIGN|ADICIONAR CAMPANHA'' where operationType=25
update ccRIALog_Operation set descripcion = ''AGREGAR GRUPO ACD|ADD ACD GROUP|ADICIONAR GRUPO ACD'' where operationType=26
update ccRIALog_Operation set descripcion = ''ELIMINAR CAMPAÑA|DELETE CAMPAIGN|ELIMINAR CAMPANHA'' where operationType=27
update ccRIALog_Operation set descripcion = ''ELIMINAR GRUPO ACD|DELETE ACD GROUP|ELIMINAR GRUPO ACD'' where operationType=28
update ccRIALog_Operation set descripcion = ''CAMBIAR ESTADO DEL CALL CENTER|CHANGE CALL CENTER STATUS|ALTERAR ESTADO DO CALL CENTER'' where operationType=29
update ccRIALog_Operation set descripcion = ''AGREGAR HORARIO|ADD SCHEDULE|ADICIONAR HORÁRIO'' where operationType=30
update ccRIALog_Operation set descripcion = ''ELIMINAR HORARIO|DELETE SCHEDULE|ELIMINAR HORÁRIO'' where operationType=31
update ccRIALog_Operation set descripcion = ''ASINGAR ROL|ASSIGN ROLE|ATRIBUIR PERFIL'' where operationType=32
update ccRIALog_Operation set descripcion = ''ASIGNAR PERMISO|ASSING PERMISSION|ATRIBUIR PERMISSÃO'' where operationType=33
update ccRIALog_Operation set descripcion = ''DUPLICAR PERMISOS|DUPLICATE PERMISSIONS|DUPLICAR PERMISSÕES'' where operationType=34
update ccRIALog_Operation set descripcion = ''ELIMINAR PERMISO|DELETE PERMISSION|ELIMINAR PERMISSÃO'' where operationType=35
update ccRIALog_Operation set descripcion = ''ACTUALIZAR CONFIGURACIÓN|UPDATE CONFIGURATION|ATUALIZAR CONFIGURAÇÃO'' where operationType=36
update ccRIALog_Operation set descripcion = ''AGREGAR PUERTO DE MARCACIÓN|ADD DIALER|ADICIONAR PORTA DE DISCAGEM'' where operationType=37
update ccRIALog_Operation set descripcion = ''ELIMINAR PUERTO DE MARCACIÓN|DELETE DIALER|ELIMINAR PORTA DE DISCAGEM'' where operationType=38
update ccRIALog_Operation set descripcion = ''AGREGAR DNIS|ADD DNIS|ADICIONAR DNIS'' where operationType=39
update ccRIALog_Operation set descripcion = ''ELIMINAR DNIS|DELETE DNIS|ELIMINAR DNIS'' where operationType=40
update ccRIALog_Operation set descripcion = ''ACTUALIZAR CONFIGURACIÓN|UPDATE SETTING|ATUALIZAR CONFIGURAÇÃO'' where operationType=41
update ccRIALog_Operation set descripcion = ''AGREGAR MENSAJE DE AUDIO|ADD AUDIO MESSAGE|ADICIONAR MENSAGEM DE ÁUDIO'' where operationType=42
update ccRIALog_Operation set descripcion = ''ELIMINAR MENSAJE DE AUDIO|DELETE AUDIO MESSAGE|ELIMINAR MENSAGEM DE ÁUDIO'' where operationType=43
update ccRIALog_Operation set descripcion = ''AUTOINICIO POR DEFECTO|AUTOSTART BY DEFAULT|INICIO AUTOMÁTICO POR PADRÃO'' where operationType=44
update ccRIALog_Operation set descripcion = ''AUTOINICIO POR FECHA|AUTOSTART BY DATE|INICIO AUTOMÁTICO POR DATA'' where operationType=45
update ccRIALog_Operation set descripcion = ''AUTOINICIO POR CONDICIÓN|AUTOSTART BY CONDITION|INICIO AUTOMÁTICO POR CONDIÇÃO'' where operationType=46
update ccRIALog_Operation set descripcion = ''AGREGAR CALIFICACIÓN|ADD DISPOSITION|ADICIONAR CLASSIFICAÇÃO'' where operationType=47
update ccRIALog_Operation set descripcion = ''ELIMINAR CALIFICACIÓN|DELETE DISPOSITION|ELIMINAR CLASSIFICAÇÃO'' where operationType=48
update ccRIALog_Operation set descripcion = ''GRUPO ACD INICIADO|ACD GROUP STARTED|GRUPO ACD INICIADO'' where operationType=49
update ccRIALog_Operation set descripcion = ''GRUPO ACD DETENIDO |ACD GROUP STOPPED|GRUPO ACD DETIDO'' where operationType=50
update ccRIALog_Operation set descripcion = ''ACTUALIZAR MARCACIÓN INTENSIVA|UPDATE INTENSIVE DIALING|ATUALIZAR DISCAGEM INTENSIVA'' where operationType=51
update ccRIALog_Operation set descripcion = ''ACTUALIZAR LISTA NEGRA POR CAMPAÑA|UPDATE DO NOT CALL LIST BY CAMPAIGN|ATUALIZAR LISTA NEGRA POR CAMPANHA'' where operationType=52
update ccRIALog_Operation set descripcion = ''ACTUALIZAR LISTA NEGRA POR CALIFICACIÓN|UPDATE DO NOT CALL LIST BY DISPOSITION|ATUALIZAR LISTA NEGRA POR CLASSIFICAÇÃO'' where operationType=53
update ccRIALog_Operation set descripcion = ''TRANSFERIR A CONTESTADORA|TRANSFER TO ANSWERING MACHINE|TRANSFERIR PARA SECRETÁRIA ELETRÔNICA'' where operationType=54
update ccRIALog_Operation set descripcion = ''TRANSFERIR A BUZÓN DE VOZ|TRANSFER TO VOICEMAIL|TRANSFERIR PARA CORREIO DE VOZ'' where operationType=55
update ccRIALog_Operation set descripcion = ''AGREGAR PLANTILLA DE CARGA|ADD IMPORT TEMPLATE|ADICIONAR MODELO DE CARREGAMENTO'' where operationType=56
update ccRIALog_Operation set descripcion = ''ELIMINAR PLANTILLA DE CARGA|DELETE IMPORT TEMPLATE|ELIMINAR MODELO DE CARREGAMENTO'' where operationType=57
update ccRIALog_Operation set descripcion = ''ACTUALIZAR PLANTILLA DE CARGA|UPDATE IMPORT TEMPLATE|ATUALIZAR MODELO DE CARREGAMENTO'' where operationType=58
update ccRIALog_Operation set descripcion = ''COPIAR TEMPLATE DE CARGA|COPY IMPORT TEMPLATE|COPIAR MODELO DE CARREGAMENTO'' where operationType=59
update ccRIALog_Operation set descripcion = ''AGREGAR NÚMERO DE CONFERENCIA|ADD CONFERENCE NUMBER|ADICIONAR NÚMERO DE CONFERÊNCIA'' where operationType=60
update ccRIALog_Operation set descripcion = ''ELIMINAR NÚMERO DE CONFERENCIA|DELETE CONFERENCE NUMBER|ELIMINAR NÚMERO DE CONFERÊNCIA'' where operationType=62
update ccRIALog_Operation set descripcion = ''AGREGAR NÚMERO DE TRANSFERENCIA|ADD TRANSFER NUMBER|ADICIONAR NÚMERO DE TRANSFERÊNCIA'' where operationType=63
update ccRIALog_Operation set descripcion = ''ACTUALIZAR NÚMERO DE TRANSFERENCIA|UPDATE TRANSFER NUMBER|ATUALIZAR NÚMERO DE TRANSFERÊNCIA'' where operationType=64
update ccRIALog_Operation set descripcion = ''CAMBIAR NOMBRE|RENAME|RENOMEAR'' where operationType=70
update ccRIALog_Operation set descripcion = ''AGREGAR MENÚ|ADD MENU|ADICIONAR MENU'' where operationType=71
update ccRIALog_Operation set descripcion = ''ACTUALIZAR NÚMERO DE CONFERENCIA|UPDATE CONFERENCE NUMBER|ATUALIZAR NÚMERO DE CONFERÊNCIA'' where operationType=61
update ccRIALog_Operation set descripcion = ''ELIMINAR MENÚ|DELETE MENU|ELIMINAR MENU'' where operationType=72
update ccRIALog_Operation set descripcion = ''Tiempo máximo de marcación|Dialing max time|Tempo máximo de discagem'' where operationType=73
update ccRIALog_Operation set descripcion = ''Marcar antes de que termine el tiempo de notas|Start dialing before wrap-up time ends|Ligar antes que termine o tempo de notas'' where operationType=74
update ccRIALog_Operation set descripcion = ''ELIMINAR NÚMERO DE TRANSFERENCIA|DELETE TRANSFER NUMBER|ELIMINAR NÚMERO DE TRANSFERÊNCIA'' where operationType=65
update ccRIALog_Operation set descripcion = ''ELIMINAR USUARIO DE GRUPOS DE TRABAJO|REMOVE USER FROM WORKGROUPS|ELIMINAR USUÁRIO DO GRUPOS DE TRABALHO'' where operationType=66
update ccRIALog_Operation set descripcion = ''ACTUALIZAR LISTA NEGRA POR GRUPO ACD|UPDATE DO NOT CALL LIST BY ACD GROUP|ATUALIZAR LISTA NEGRA POR GRUPO ACD'' where operationType=67
update ccRIALog_Operation set descripcion = ''Asignar subcalificaciones|Assign subdispositions|Atribuir subclassificações'' where operationType=68
update ccRIALog_Operation set descripcion = ''Desasignar subcalificaciones|Unassign subdispositions|Eliminar atribuição de subclassificações'' where operationType=69
update ccRIALog_Operation set descripcion = ''Reintentos en no contesta (min)|Redial attemps on no answer (min)|Tentativas de ligação em não atende (min)'' where operationType=75
update ccRIALog_Operation set descripcion = ''Reintentar no contesta (veces)|Redial on no answer (times)|Ligar novamente em não atende (vezes)'' where operationType=76
update ccRIALog_Operation set descripcion = ''Reintentos en ocupado (min)|Redial attemps on busy (min)|Tentativas de ligação em ocupado (min)'' where operationType=77
update ccRIALog_Operation set descripcion = ''Reintentar ocupados (veces)|Redial on busy (times)|Ligar novamente em ocupado (vezes)'' where operationType=78
update ccRIALog_Operation set descripcion = ''Reintentos en fax (min)|Redial attemps on fax (min)|Tentativas de ligação em fax (min)'' where operationType=79
update ccRIALog_Operation set descripcion = ''Reintentar fax (veces)|Redial on fax (times)|Ligar novamente em fax (vezes)'' where operationType=80
update ccRIALog_Operation set descripcion = ''Reintentos en contestadora (min)|Redial attemps on answering machine (min)|Tentativas de ligação em secretária eletrônica (min)'' where operationType=81
update ccRIALog_Operation set descripcion = ''Reintentar contestadora (veces)|Redial on answering machine (times)|Ligar novamente em secretária eletrônica (vezes)'' where operationType=82
update ccRIALog_Operation set descripcion = ''ANI|ANI|ANI'' where operationType=83
update ccRIALog_Operation set descripcion = ''Prefijo de marcación (predictivo)|Dialing prefix (automatic)|Prefixo de discagem (automático)'' where operationType=84
update ccRIALog_Operation set descripcion = ''Prefijo de marcación (llamada manual)|Dialing prefix (manual call)|Prefixo de discagem (chamada manual)'' where operationType=85
update ccRIALog_Operation set descripcion = ''Prefijo de marcación (transferencia)|Dialing prefix (transfer)|Prefixo de discagem (transferência)'' where operationType=86
update ccRIALog_Operation set descripcion = ''Intervalo de auto-reprogramación (min)|Auto-call back interval (min)|Intervalo de reprogramação automática (min)'' where operationType=87
update ccRIALog_Operation set descripcion = ''Orden de marcación|Dialing order|Ordem de discagem'' where operationType=88
update ccRIALog_Operation set descripcion = ''Detectar contestadora|Answering machine detection|Detectar secretária eletrônica'' where operationType=89
update ccRIALog_Operation set descripcion = ''Marcación manual|Manual dialing|Discagem manual'' where operationType=90
update ccRIALog_Operation set descripcion = ''Marcación intensiva|Intensive dialing|Discagem intensiva'' where operationType=91
update ccRIALog_Operation set descripcion = ''Marcación progresiva|Progressive dialing|Discagem progressiva'' where operationType=92
update ccRIALog_Operation set descripcion = ''Callback exclusivo|Exclusive callback|Callback exclusiva'' where operationType=93
update ccRIALog_Operation set descripcion = ''Detectar buzón de voz|Voicemail detection|Detectar correio de voz'' where operationType=94
update ccRIALog_Operation set descripcion = ''Compliance|Compliance|Compliance'' where operationType=95
update ccRIALog_Operation set descripcion = ''Callback en evento fallido|Callback on failure|Callback no caso de falha'' where operationType=96
update ccRIALog_Operation set descripcion = ''Lista de ANI local|Local ANI list|Lista de ANI local'' where operationType=97
update ccRIALog_Operation set descripcion = ''Espacio en cola|Queue space|Espaço na fila de espera'' where operationType=98
update ccRIALog_Operation set descripcion = ''Tiempo de notas|Wrap-up time|Tempo de notas'' where operationType=99
update ccRIALog_Operation set descripcion = ''Mostrar calificación|Show disposition|Mostrar classificação'' where operationType=100
update ccRIALog_Operation set descripcion = ''Editar call key|Edit call key|Editar call key'' where operationType=101
update ccRIALog_Operation set descripcion = ''Escuchar llamadas manuales|Listen manual calls|Escutar chamadas manuais'' where operationType=102
update ccRIALog_Operation set descripcion = ''Detener grabación al transferir|Stop recording when transferring|Parar gravação ao transferir'' where operationType=103
update ccRIALog_Operation set descripcion = ''ACTUALIZAR HORARIO|UPDATE SCHEDULE|ATUALIZAR HORÁRIO'' where operationType=104
update ccRIALog_Operation set descripcion = ''LLAMADAS POR AGENTE|CALLS BY AGENT|CHAMADAS POR AGENTE'' where operationType=105
update ccRIALog_Operation set descripcion = ''AGREGAR ANI|ADD ANI|ADICIONAR ANI'' where operationType=106
update ccRIALog_Operation set descripcion = ''ELIMINAR ANI|DELETE ANI|ELIMINAR ANI'' where operationType=107
update ccRIALog_Operation set descripcion = ''ACTUALIZAR ANI|UPDATE ANI|ATUALIZAR ANI'' where operationType=108
update ccRIALog_Operation set descripcion = ''AGREGAR LISTA|ADD LIST|ADICIONAR LISTA'' where operationType=109
update ccRIALog_Operation set descripcion = ''ELIMINAR LISTA|DELETE LIST|ELIMINAR LISTA'' where operationType=110
update ccRIALog_Operation set descripcion = ''ACTUALIZAR LISTA|UPDATE LIST|ATUALIZAR LISTA'' where operationType=111
update ccRIALog_Operation set descripcion = ''Tiempo de notas|Wrap-up time|Tempo de notas'' where operationType=112
update ccRIALog_Operation set descripcion = ''Tiempo máximo de espera|Max waiting time|Tempo máximo na fila de espera'' where operationType=113
update ccRIALog_Operation set descripcion = ''Número máximo de espera|Max number in queue|Número máximo na fila de espera'' where operationType=114
update ccRIALog_Operation set descripcion = ''Destino tiempo máximo|Destination time max|Destino tempo máximo'' where operationType=115
update ccRIALog_Operation set descripcion = ''Destino número máximo|Destination queue max|Destino número máximo'' where operationType=116
update ccRIALog_Operation set descripcion = ''Destino fuera de servicio|Destination out of service|Destino fora de serviço'' where operationType=117
update ccRIALog_Operation set descripcion = ''Destino fuera de horario|Destination out of schedule|Destino fora de horário'' where operationType=118
update ccRIALog_Operation set descripcion = ''Iniciar tiempo de notas|Start wrap-up time|Iniciar tempo de notas'' where operationType=119
update ccRIALog_Operation set descripcion = ''Posición en cola|Queue position|Posição na fila de espera'' where operationType=120
update ccRIALog_Operation set descripcion = ''Regresar llamada (segs)|Call back (secs)|Retornar chamada (segs)'' where operationType=121
update ccRIALog_Operation set descripcion = ''Prefijo de marcación (desborde)|Dialing prefix (overflow)|Prefixo de discagem (transbordamento)'' where operationType=122
update ccRIALog_Operation set descripcion = ''Incrementar prioridad después de (segs)|Increase priority after (secs)|Incrementar prioridade depois de (segs) '' where operationType=123
update ccRIALog_Operation set descripcion = ''RENOMBRAR DNIS|RENAME DNIS|RENOMEAR DNIS'' where operationType=124
update ccRIALog_Operation set descripcion = ''BLOQUEAR DNIS|BLOCK DNIS|BLOQUEAR DNIS'' where operationType=125
update ccRIALog_Operation set descripcion = ''DESBLOQUEAR DNIS|UNBLOCK DNIS|DESBLOQUEAR DNIS'' where operationType=126
update ccRIALog_Operation set descripcion = ''ACTUALIZAR CALIFICACIÓN|UPDATE DISPOSITION|ATUALIZAR CLASSIFICAÇÃO'' where operationType=127
update ccRIALog_Operation set descripcion = ''AGREGAR CAMPAÑA CLON|ADD CLONE CAMPAIGN|ADICIONAR CAMPANHA CLONE'' where operationType=128
update ccRIALog_Operation set descripcion = ''ELIMINAR CAMPAÑA CLON|DELETE CLONE CAMPAIGN|ELIMINAR CAMPANHA CLONE'' where operationType=129
update ccRIALog_Operation set descripcion = ''Configuración de callbacks|Callbacks Configuration|Configuração de callbacks'' where operationType=130
update ccRIALog_Operation set descripcion = ''AGREGAR LISTA NEGRA POR CALIFICACIÓN|ADD DO NOT CALL LIST BY DISPOSITION|ADICIONAR LISTA NEGRA POR CLASSIFICAÇÃO'' where operationType=131
update ccRIALog_Operation set descripcion = ''ELIMINAR LISTA NEGRA POR CALIFICACIÓN|DELETE DO NOT CALL LIST BY DISPOSITION|ELIMINAR LISTA NEGRA POR CLASSIFICAÇÃO'' where operationType=132
update ccRIALog_Operation set descripcion = ''AGREGAR LISTA NEGRA POR CAMPAÑA|ADD DO NOT CALL LIST BY CAMPAIGN|ADICIONAR LISTA NEGRA POR CAMPANHA'' where operationType=133
update ccRIALog_Operation set descripcion = ''ELIMINAR LISTA NEGRA POR CAMPAÑA|DELETE DO NOT CALL LIST BY CAMPAIGN|ELIMINAR LISTA NEGRA POR CAMPANHA'' where operationType=134
update ccRIALog_Operation set descripcion = ''AGREGAR LISTA NEGRA POR GRUPO ACD|ADD DO NOT CALL LIST BY ACD GROUP|ADICIONAR LISTA NEGRA POR GRUPO ACD'' where operationType=135
update ccRIALog_Operation set descripcion = ''ELIMINAR LISTA NEGRA POR GRUPO ACD|DELETE DO NOT CALL LIST BY ACD GROUP|ELIMINAR LISTA NEGRA POR GRUPO ACD'' where operationType=136
update ccRIALog_Operation set descripcion = ''AGREGAR CORREO ELECTRÓNICO|ADD EMAIL ADDRESS|ADICIONAR ENDEREÇO DE E-MAIL'' where operationType=137
update ccRIALog_Operation set descripcion = ''ELIMINAR RELACIÓN CORREO/GRUPO ACD|DELETE EMAIL/ACD GROUP RELATION|ELIMINAR RELAÇÃO E-MAIL/GRUPO ACD'' where operationType=138
update ccRIALog_Operation set descripcion = ''ACTUALIZAR RELACIÓN CORREO/GRUPO ACD|UPDATE EMAIL/ACD GROUP RELATION|ATUALIZAR RELAÇÃO E-MAIL/GRUPO ACD'' where operationType=139
update ccRIALog_Operation set descripcion = ''ELIMINAR CORREO ELECTRÓNICO|DELETE EMAIL ADDRESS|ELIMINAR ENDEREÇO DE E-MAIL'' where operationType=140
update ccRIALog_Operation set descripcion = ''AGREGAR RELACIÓN CORREO/GRUPO ACD|ADD EMAIL/ACD GROUP RELATION|ADICIONAR RELAÇÃO E-MAIL/GRUPO ACD'' where operationType=141
update ccRIALog_Operation set descripcion = ''ACTUALIZAR CORREO ELECTRÓNICO|UPDATE EMAIL ADDRESS|ATUALIZAR ENDEREÇO DE E-MAIL'' where operationType=142
update ccRIALog_Operation set descripcion = ''AGREGAR USUARIO AVRS|ADD AVRS USER|ADICIONAR USUÁRIO AVRS'' where operationType=143
update ccRIALog_Operation set descripcion = ''ELIMINAR USUARIO AVRS|DELETE AVRS USER|ELIMINAR USUÁRIO AVRS'' where operationType=144
update ccRIALog_Operation set descripcion = ''AGREGAR SUBCALIFICACIÓN|ADD SUBDISPOSITION|ADICIONAR SUBCLASSIFICAÇÃO'' where operationType=145
update ccRIALog_Operation set descripcion = ''ELIMINAR SUBCALIFICACIÓN|DELETE SUBDISPOSITION|ELIMINAR SUBCLASSIFICAÇÃO'' where operationType=146
update ccRIALog_Operation set descripcion = ''ACTUALIZAR SUBCALIFICACIÓN|UPDATE SUBDISPOSITION|ATUALIZAR SUBCLASSIFICAÇÃO'' where operationType=147
update ccRIALog_Operation set descripcion = ''Servicio SCRUB de listas negras|DNC SCRUB service|Serviço SCRUB de listas negras'' where operationType=148
update ccRIALog_Operation set descripcion = ''Ver historial de listas negras|View do not call lists log|Ver histórico de listas negras'' where operationType=149
update ccRIALog_Operation set descripcion = ''Actualizar prioridad de camapañas|Update campaign priority|Atualizar prioridade das campanhas'' where operationType=150
update ccRIALog_Operation set descripcion = ''Actualizar prioridad de agentes|Update agent priority|Atualizar prioridade dos agentes'' where operationType=151
update ccRIALog_Operation set descripcion = ''Actualiza Validacion Zona Horaria (Manual)|Update Time Zone Validation (Manual)|Atualiza Validação Zona Horario'' where operationType=152
update ccRIALog_Operation set descripcion = ''Actualiza Llamadas por Encuesta|Update Calls by Survey|Actualiza Chamadas por Enquéritos'' where operationType=153
update ccRIALog_Operation set descripcion = ''Actualiza Script IVR|Update IVR Script|Atualiza Script IVR'' where operationType=154
update ccRIALog_Operation set descripcion = ''Actualiza Tiempo de Chat Inactivo|Update Inactive Chat Time|Atualiza Tempo do Chat Inativo'' where operationType=156
update ccRIALog_Operation set descripcion = ''Actualiza Chats Maximos|Update Max Chats|Atualiza Chats Máximos'' where operationType=157
update ccRIALog_Operation set descripcion = ''Actualiza Dominio Chat|Update Chat Domain|Atualiza Domínio Chat'' where operationType=158
update ccRIALog_Operation set descripcion = ''Actualiza Tiempo de desborde Chat|Update Chat Time Overflow|Atualiza Tempo de transborde Chat'' where operationType=159
update ccRIALog_Operation set descripcion = ''Actualiza Cola de desborde Chat|Update Chat Queue Overflow|Atualiza Fila de transborde Chat'' where operationType=160
update ccRIALog_Operation set descripcion = ''Actualiza Dejar mensaje manualmente|Update Leave prerecorded message|Atualiza Deixar messagem manualmente'' where operationType=161
update ccRIALog_Operation set descripcion = ''Actualiza Llamadas manuales en Chat|Update Manual Calls on Chat|Atualiza Chamadas manuais no Chat'' where operationType=162
update ccRIALog_Operation set descripcion = ''Actualiza Intervalo remarcacion en canceladas|Update Redial Interval on Cancelled|Atualiza Intervalo rediscar em canceladas'' where operationType=164
update ccRIALog_Operation set descripcion = ''Actualiza Funcion especial DTMF|Update Special Function DTMF|Atualiza Função especial DTMF'' where operationType=165
update ccRIALog_Operation set descripcion = ''Actualiza Cabecera SIP Personalizada|Update Custom SIP Header|Atualiza Cabeçalho SIP Pessonalizada'' where operationType=166
update ccRIALog_Operation set descripcion = ''Actualiza Pausar y continuar grabacion|Update Pause and resume recording|Atualiza Pausar e continuar grabação'' where operationType=167'
    	EXEC(@Sql)

		set @process = 'CW-943 ETIQUETAS EN PORTUGUES -- Version BD 119.122 -- '
    	set @Sql= 'update ccRIACat_AdminPermissions set per_desc = ''Iniciar campañas|Start campaigns|Iniciar campanhas'' where per_id=1
update ccRIACat_AdminPermissions set per_desc = ''Modificar orden de marcación|Change dialing order|Alterar ordem de discagem'' where per_id=2
update ccRIACat_AdminPermissions set per_desc = ''Eliminar campañas y grupos ACD|Delete campaigns and ACD groups|Eliminar campanhas e grupos ACD'' where per_id=3
update ccRIACat_AdminPermissions set per_desc = ''Sólo monitorizar|Monitor only|Só monitorar'' where per_id=4
update ccRIACat_AdminPermissions set per_desc = ''Acceder a reportes|Access reports|Acessar aos relatórios'' where per_id=5
update ccRIACat_AdminPermissions set per_desc = ''Ver registros de sistema|Retrieve system records|Ver registros do sistema'' where per_id=6
update ccRIACat_AdminPermissions set per_desc = ''Cambiar calificación|Change disposition|Alterar classificação'' where per_id=7
update ccRIACat_AdminPermissions set per_desc = ''Habilitar clicker|Enable clicker|Habilitar a função clicker'' where per_id=8
update ccRIACat_AdminPermissions set per_desc = ''Ver reportes por grupo|View reports by workgroup|Ver relatórios por grupo'' where per_id=9

update ccRIACat_AdminPermissions set release = ''821b5a60b5cdf4238e4ebc5e3e9e5279ddb7f0eddc73385e8019bd3c67341cc502e4dee671b81f8f1a53962d4eef2c7e201e2be748590eff696aaf6e931cac15'' where per_id=1
update ccRIACat_AdminPermissions set release = ''046f01019cd082288c234d152c6955e00a2303e3cadd3a9b97ca9302b913eae3dc61c049bbd0f6924abe22d2b7d3db3a088299d64d9056962b75bd6e46599b8f6f71bc537a232b0b7cd56035e4683ac0'' where per_id=2
update ccRIACat_AdminPermissions set release = ''85ffc36fa7999666ac426f9853c663507fd45ad22dddcc8ec2f710d2df6e6b89d30087f405a9d09847f2b04615a5c61451a6775ac3a0ed72d6c32a36a0947c9efa371d334b23f8df96878b9f3ee5102febff14c2a2fd5171d0f4c0c231d1fd5284f9dc14e26ce43f29d0a0cca50f4f26'' where per_id=3
update ccRIACat_AdminPermissions set release = ''24738a5d4db9c7b4096708b8a8eb3fde8fed0eb7e9518fd22b57344aaffb80c460cb78ad853b38aa5970bb5a2b69b00f'' where per_id=4
update ccRIACat_AdminPermissions set release = ''1ec8f5efe4acc903d56c85384bafc10dbf0994ea5ebba233f05bf7767dbb6da009f8616aaf1eaa3fd5e5f89c2d8d75c3b047a1026b68b85b2c546d2889b5cec9'' where per_id=5
update ccRIACat_AdminPermissions set release = ''420634812330af1a5f7a75617ab6f51c810537c1d2f87811386d12fc56d45ef5d6b4e11ef37797e24a93a445b205743a984a1211120be4e57316abcc9abd3abec195fc9631d1bffee8e6667b494401df'' where per_id=6
update ccRIACat_AdminPermissions set release = ''2615a98148da7446b27e650aa6a299c11af7beecdbc249cf9a18e19e7ff4a61c36cb2b83200a3738d56524a00d132a426230a0b58caad126b513a76cb321565b8476379e5a0921be7c58362eaee96956'' where per_id=7
update ccRIACat_AdminPermissions set release = ''a11d51de884e6a2f3f0047f5105b81a5996df0f179521f93e42c8737558764dfcdbdbeeac2ef8abb51cac75cc4356dfcba264e81ea4e10c5509e626f5258b2e0'' where per_id=8
update ccRIACat_AdminPermissions set release = ''4fa74acb1f6a68e4c30f0b01ff93a04479224b485615cbaa3c877824cb7636b50e9edb8391888975e318e3dca9376f55ae6e04a09ab4f9b853ab06fa03f43ceb0fb9f96c8469f8c2af70a55655b4a870'' where per_id=9'
    	EXEC(@Sql)
	
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
