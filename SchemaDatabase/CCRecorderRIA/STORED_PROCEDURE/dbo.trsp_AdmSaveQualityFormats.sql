CREATE PROCEDURE [dbo].[trsp_AdmSaveQualityFormats]		
			@bCrea smallint,
			@id_formato int,
			@version int,
			@sup_id int,
			@nombre_formato varchar(50),
			@peso_formato int,
			@type int=1

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

				IF (@bCrea = 1)
					BEGIN
						set @id_formato = (select isnull(max(id_formato),0) from RIA_FORMATOS) + 1
						set @version = 1
						insert CCRecorderRIA.dbo.RIA_FORMATOS (id_formato, nombre,id_creador,fecha_creado,activo,peso,version,tipo) values (@id_formato, @nombre_formato, @sup_id, GetDate(),1, @peso_formato,@version,@type)
					END

				ELSE
					BEGIN

					set @version = @version + 1
					insert CCRecorderRIA.dbo.RIA_FORMATOS (id_formato, nombre,id_creador,fecha_creado,activo,peso,version,tipo) values (@id_formato, @nombre_formato, @sup_id, GetDate(),1, @peso_formato,@version,@type)

					END

			END