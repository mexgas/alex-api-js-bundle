CREATE PROCEDURE [dbo].[ccsp_RIACATDialer]
@Descripcion varchar(40)='',
@dialer_id varchar(5)='',
@Port int = 0, -- se cambia tipo de dato
@Status varchar(1)='',
@Tipo varchar(2),
@carrier_id varchar(5)='',--by odc
@xfertype smallint=0,
--Variables para insertar varios
@PortIni int = 0,
@PortEnd int = 0,
@sql as nvarchar(1000)='',
@dialer_ids varchar(2000)=''

AS
set nocount on
--declare @sql as nvarchar(1000)
--declare @dialer_ids nvarchar(max)


if @Tipo=0 --All Dialers
 begin
	SELECT dialer_id, Descripcion FROM ccoDialers WITH(NOLOCK)
	return(0)
 end

if @Tipo=1 --Query
 begin
	SELECT Puerto, Descripcion, Status, dialer_id, p.descrip, xt.description FROM ccoDialers d
	join cstoProvedor p on p.provedor_id=d.provedor_id
	join ccoxfertype xt on xt.xfertype_id=d.xfertype
	ORDER BY dialer_id
	return(0)
 end

if @Tipo=2 --Insert
 begin
	if @carrier_id=0
	 begin
		select top 1 @carrier_id=provedor_id from cstoProvedor
	 end

	if exists(select Descripcion from ccoDialers where (Descripcion=@Descripcion or Puerto=@Port))
	 begin
		select 1
		return(0)
	 end

	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype) Select @Descripcion, @Port, @Status, @carrier_id, @xfertype
	return(0)
 end

if @Tipo=3 --Update
 begin
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion and dialer_id <> @Dialer_id)
	 begin
		select 1--, 'Nombre o puerto en Uso'
		return(0)
	 end

	if exists(select Puerto from ccoDialers where Puerto=@Port and dialer_id <> @Dialer_id)
	 begin
		select 1--, 'Nombre o puerto en Uso'
		return(0)
	 end

	Update ccoDialers set Descripcion=case @Descripcion when '' then Descripcion else @Descripcion end,
	 Puerto=case @Port when '' then Puerto else @Port end, Status=case @status when '' then Status else @status end,
	 provedor_id=case @carrier_id when '' then provedor_id else @carrier_id end,
	 xfertype = case @xfertype when 0 then xfertype else @xfertype end
	where Dialer_id=cast(@dialer_id as int)
	return(0)
 end

if @Tipo=4 --Delete
 begin
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id=@dialer_id)
	 begin
		select 1--, 'Existe alguna campaña que esta utilizando este dialer'
		return(0)
	 end

	delete ccoDialers Where Dialer_id=@dialer_id
	return(0)
 end

if @Tipo=5 --cat. de tipo xfer
begin
	SELECT xfertype_id, description FROM ccoxfertype WITH(NOLOCK)
	return(0)
end

if @Tipo=6 --Insert more than one dialers
begin
	create table #tempPortTable( portId int primary key)
	if @carrier_id=0
		begin
			select top 1 @carrier_id=provedor_id from cstoProvedor
		end

	begin transaction
		while @portIni<=@portEnd begin
		insert into #tempPortTable values(@portIni)
		set @portIni=@portIni+1
		end
	commit transaction

	Insert ccoDialers (Descripcion, Puerto, [Status], provedor_id, xfertype)
	select @Descripcion + cast(A.portId as varchar(10)),A.portId as puerto,@Status,@carrier_id as provedor_id,@xfertype as xfertype
	from #tempPortTable A left join ccoDialers B on A.portId=B.Puerto
	where B.Puerto is null

	drop table #tempPortTable

	return(0)
end

if @Tipo=7 --Delete more than one dialers
begin
	set @sql='
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id in ('+@dialer_ids+'))
	begin
		select 1--, ''Existe alguna campaña que esta utilizando este dialer''
	end
	ELSE delete from ccoDialers where dialer_id in('+@dialer_ids+')
	'
	exec (@sql)

	return(0)
end

set nocount off