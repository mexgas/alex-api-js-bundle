use CCenterRIA

IF NOT EXISTS (Select * from ccSettings2 where setting_id = 261) begin
	INSERT INTO ccSettings2 VALUES (261, '192.168.1.31', 'Ubicación del AdminMachine',
		1, 'GRL', 'IP o Hostname del servidor donde se encuentra el AdminMachine',
		'AdminMachine location',0,
		'^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$')
	end

IF NOT EXISTS (Select * from ccSettings2 where setting_id = 262) begin
	INSERT INTO ccSettings2 VALUES (262, '1', 'Version con/sin estado',
		1, 'GRL', 'Indica si se realizan las consultas a la webApi o StateMachine',
		'Version With/Without state',0,
		'^[0-1]$')
	end

	update ccSettings2 set valor = '0' where setting_id = 262