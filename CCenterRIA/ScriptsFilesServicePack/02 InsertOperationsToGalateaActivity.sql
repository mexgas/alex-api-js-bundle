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