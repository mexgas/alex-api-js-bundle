CREATE PROCEDURE dbo.ccsp_RIACATCarrier
@carrier_id smallint,
@name varchar(30),
@Type tinyint,
@prefix varchar(20)
AS
if( @Type=0)
	begin
		SELECT	provedor_id
				, Descrip, isnull(prefix,'') prefix
		FROM cstoProvedor WITH(NOLOCK)
	end

if( @Type=1)
	begin
		Select provedor_id as Id, Descrip as Descripción, isnull(prefix,'') as Prefijo from cstoProvedor order by Id
	end
If( @Type=2)
	begin
		if exists(select provedor_id from cstoProvedor where Descrip = @name)
			select 1, 'Nombre en Uso'
		else
			insert into cstoProvedor (descrip, prefix) values (@name, @prefix)
	end
if( @Type=3)
	begin
		if exists(select provedor_id from cstoTarifa where provedor_id = @carrier_id)
			select 2 -- Tiene Tarifas asignadas
		else if exists( select provedor_id from ccoDialers where provedor_id = @carrier_id)
			select 3 -- Tiene Dialers asignados
		else
		delete cstoProvedor where provedor_id = @carrier_id
	end
if( @Type=4)
	begin
		update cstoProvedor set
		 descrip = case when @name = '' then descrip else @name end,
		 prefix = case when @prefix = '' then prefix else @prefix end
		where provedor_id = @carrier_id
	end