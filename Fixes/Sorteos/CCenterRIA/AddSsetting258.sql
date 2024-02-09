use CCenterRIA

IF NOT EXISTS (Select * from ccSettings2 where setting_id = 258) begin
	INSERT INTO ccSettings2 VALUES (258, '192.168.1.31', 'Ubicación del AdminMachine',
		1, 'GRL', 'IP o Hostname del servidor donde se encuentra el AdminMachine',
		'AdminMachine location',0,
		'^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$')
	end