CREATE  procedure [dbo].[ccsp_RIAImageHandler]
	@option int,
	@imageId int= null,
	@path varchar(100)= null

	AS

	if @option = 1 --Load All images
	begin
		select * from ccRIAImages where idImage=@imageId
	end





	if @option = 2 --insert images
	begin
		if (select count(path) from ccRIAImages where path=@path) > 0
			begin
				select -1 -- Ya existe imagen con ese nombre
			end
		else
			begin
				insert into ccRIAImages values (@path)
				select @imageId = scope_identity()
				select @imageId
			end
	end



	if @option = 3 --Update Path images
	begin
		if ( select count(idImage) from ccRIAImages where idImage=@imageId) = 0
			begin
				select -1 --EL Id no se encuentra asociado
			end
		else
			begin
				update ccRIAImages set path=@path where idImage=@imageId
			end
	end







	if @option = 4 --Delete images
	begin
		if ( select count(idImage) from ccRIAImages where idImage=@imageId) = 0
			begin
				select -1 --EL Id no se encuentra asociado
			end
		else
			begin
				delete ccRIAImages where idImage=@imageId
			end
	end





	if @option = 5 --Load All images
	begin
		if (select count(idImage) from ccRIAImages) > 0
			BEGIN
				select * from ccRIAImages  order by 1
			END
		ELSE
			BEGIN
				select -1
			END
	end



	if @option = 6 --Return path images
	begin
		if ( select count(idImage) from ccRIAImages where idImage=@imageId) = 0
			begin
				select -1 --EL Id no se encuentra asociado
			end
		else
			begin
				select path from ccRIAImages where idImage=@imageId
			end
	end