create procedure ccsp_DLRgetDialMask
			@cam_id int,
			@phone varchar(50)
			as
			declare @checkLd_In_ANILst smallint = 0
			declare @ani varchar(50), @pais varchar(3)

			SELECT @pais = valor
			FROM ccSettings WITH (NOLOCK)
			WHERE setting_id = 104

			SELECT @checkLd_In_ANILst = valor 
			FROM ccsettings WITH (NOLOCK) 
			WHERE setting_id = 213

			IF @pais = 1
			BEGIN ---Mexico
				If (@cam_id > 0 AND @checkLd_In_ANILst = 1)
				BEGIN
					select @ani = ltrim(rtrim(ani)) FROM ccCamps nolock WHERE cam_id = @cam_id
					If datalength(@ani) > 0
					BEGIN
						SELECT @ani	ani
						RETURN (0)
					END

					IF len(@phone) < 10 select @phone = dbo.Completa(@phone, @pais, '')

					IF len(@phone) < 10 or isnumeric(@phone) <= 0 select '' ani

					select @phone = right(@phone, 10)

					SELECT TOP 1 @ani=ltrim(rtrim(telAni)) FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
							  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
							  WHERE cam_id = @cam_id and telAni <> '''' and area = left(@phone, 3)
					If datalength(@ani) > 0
					BEGIN
						SELECT @ani ani
						RETURN (0)
					END
					SELECT TOP 1 @ani=ltrim(rtrim(telAni)) FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
							  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
							  WHERE cam_id = @cam_id and telAni <> '''' and area = left(@phone, 2)
					If datalength(@ani) > 0
					BEGIN
						SELECT @ani ani
						RETURN (0)
					END
				END
				select '' ani
			END