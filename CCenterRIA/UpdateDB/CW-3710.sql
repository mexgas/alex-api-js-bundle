set @process = 'CW-3610 Setting_ID 217 Información del certificado'
    set @Sql= '
	IF not exists (SELECT * FROM ccSettings WHERE setting_id = 217)
	INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
	VALUES	(217, 
			''D:\Centerware\Sites\certs\nuxiba_pfx.pfx|e7451896fd98715c9e67f110351b5719'',
			''Parámetros del Certificado de seguridad (.PFX)'',	
			1,
			''X'',
			''Información del certificado de seguridad Ubicación|Contraseña cifrada'',
			''Security Certificate Information'',
			0,
			 ''.*'')
	'
exec (@sql)