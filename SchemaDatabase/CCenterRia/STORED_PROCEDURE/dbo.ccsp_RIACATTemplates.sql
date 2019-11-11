CREATE PROCEDURE [dbo].[ccsp_RIACATTemplates]
@User smallint,
--@name varchar(50),
@Type tinyint 

AS

	if( @Type=1)
		begin
			Select * from ccTemplates where user_id = @User
		end
--	If( @Type=2)
--		begin
--	if ( select count(*) from cctiposlistanegra where tipolista=@name) > 0
--			select 1, 'Nombre en Uso'
--	else
--			insert into cctiposlistanegra (tipolista) values(@name)
--		end
--	if( @Type=4)
--		begin
--			update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
--		end