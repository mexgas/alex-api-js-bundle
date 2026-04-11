use CCenterRIA;
GO

IF NOT EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 175
)
BEGIN
	INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
	VALUES (175, 'Asignar calificación de agente virtual', 'Assign virtual agent disposition', 'Atribuir classificação de agente virtual');
END
IF NOT EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 176
)
BEGIN
	INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
	VALUES (176, 'Desasignar calificación de agente virtual', 'Unassign virtual agent disposition', 'Cancelar atribuição de classificação de agente virtual');
END

IF NOT EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 177
)
BEGIN
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
    VALUES (
        177,
        'Eliminar calificación de agente virtual',
        'Delete virtual agent disposition',
        'Excluir classificação de agente virtual'
    );
END

IF NOT EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 178
)
BEGIN
	insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
	values (178, 'Crear calificación de agente virtual', 'Create virtual agent disposition', 'Criar classificação de agente virtual')
END

IF NOT EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 179
)
BEGIN
	insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
	values (179, 'Editar calificación de agente virtual', 'Edit virtual agent disposition', 'Editar classificação de agente virtual')
END

--Nombre
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_NAME' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Name_cal')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_NAME', 'cctipoCalif_IA', 'Name_cal')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_NAME')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_NAME', 'Nombre', 'Name', 'Nome')
END

--Descripción
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_DESCRIPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Description_cal')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_DESCRIPTION', 'cctipoCalif_IA', 'Description_cal')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_DESCRIPTION')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_DESCRIPTION', 'Descripción', 'Description', 'Descrição')
END

--Devolver llamada 
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_CALLBACK' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'CanReprogram')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_CALLBACK', 'cctipoCalif_IA', 'CanReprogram')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_CALLBACK', 'Devolver llamada', 'Call back', 'Retornar chamada')
END
--Color
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_COLOR' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'Color')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_COLOR', 'cctipoCalif_IA', 'Color')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_COLOR')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_COLOR', 'Color', 'Color', 'Cor')
END
--Transferencia
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_TRANSFER' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplTransfer')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER', 'cctipoCalif_IA', 'AplTransfer')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER', 'Transferir llamada', 'Transfer call', 'Tipo da transferência')
END
--Transferencia RadioButton
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'TransferOpcion')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_OPTION', 'cctipoCalif_IA', 'TransferOpcion')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_OPTION', 'Tipo de transferencia', 'Transfer type', 'Tipo da transferência')
END
--Extracción
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_EXTRACTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplExtDate')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_EXTRACTION', 'cctipoCalif_IA', 'AplExtDate')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_EXTRACTION')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_EXTRACTION', 'Capturar datos automáticamente', 'Capture data automatically', 'Capturar dados automaticamente')
END
--Descripción Extracción
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'ExtDescription')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION', 'cctipoCalif_IA', 'ExtDescription')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION', 'Datos a capturar', 'Data to capture', 'Dados a capturar')
END
--LN
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'AI_UPDATE_DISPOSITION_DNC' 
 	AND tableName = 'cctipoCalif_IA' AND colunName = 'AplBlackList')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values ('AI_UPDATE_DISPOSITION_DNC', 'cctipoCalif_IA', 'AplBlackList')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_DNC')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_DNC', 'Adicionar registro a lista negra', 'Add record to DNC list', 'Adicionar registro a lista negra')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_1')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_OPTION_1', 'Por escalamiento', 'On escalation', 'Por escalonamento')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_2')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_OPTION_2', 'Por gestión exitosa', 'On successful interaction', 'Por interação bem‑sucedida')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_OPTION_3')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_OPTION_3', 'Por seguimiento (IVR)', 'On follow‑up (IVR)', 'Por acompanhamento (IVR)')
END



IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_1')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_CALLBACK_OPTION_1', 'Deshabilitado', 'Disabled', 'Desativado')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_2')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_CALLBACK_OPTION_2', 'Programable', 'Custom', 'Programável')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_CALLBACK_OPTION_3')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_CALLBACK_OPTION_3', 'Por defecto', 'Default', 'Padrão')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_CAMPAIGN')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_CAMPAIGN', ' Destino de transferencia: Campaña', 'Transfer destination: Campaign', 'Destino da transferência: Campanha')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_NUMBER')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_NUMBER', 'Destino de transferencia: Número externo', 'Transfer destination: External number', 'Destino da transferência: Número externo')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = 'AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_DIRECTORY')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values ('AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_DIRECTORY', 'Destino de transferencia: Directorio', 'Transfer destination: Transfer list', 'Destino da transferência: Catálogo')
END

GO