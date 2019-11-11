CREATE procedure xx_ClienteActividad 
@bloquear int = 0
as 
declare @usr varchar(50)
declare @pc varchar(50)
declare @existe int

select @usr = user_name(), @pc= host_name()
select @existe = count(*) from xxClienteConexiones where computadora = @pc
if @existe =0 
	insert into xxClienteConexiones values ( @pc, @usr, getdate(), 0 )
else
	update xxClienteConexiones  set usuario = @usr, fecha = getdate() where computadora = @pc

if @bloquear = 0
begin
	update xxClienteConexiones  set activo =0 where computadora = @pc
	select 2
end
else
begin
	select @existe = count(*) from xxClienteConexiones where activo <> 0 and computadora <> @pc
	if @existe > 0
		select 0
	else
	begin
		update xxClienteConexiones  set activo =1 where computadora = @pc
		select 1
	end
end