use CCenterRIA

IF NOT EXISTS (Select * from ccSettings2 where setting_id = 259) begin
	INSERT INTO ccSettings2 VALUES (259, '..\..\Sites\Galatea\GalateaAdminWS\ExcelFiles', 'Ruta donde lee los archivos xls o csv',
		1, 'GRL', 'Ruta donde lee los archivos xls o csv',
		'Path where it reads the xls or csv files',0,
		'.+')
	end