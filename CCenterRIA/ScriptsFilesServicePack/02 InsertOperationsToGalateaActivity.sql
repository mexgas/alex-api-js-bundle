use CCenterRIA;
GO

IF NOT EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 175
)
BEGIN
	INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
	VALUES (175, 'Asignar calificaci�n de agente virtual', 'Assign virtual agent disposition', 'Atribuir classifica��o de agente virtual');
END
IF NOT EXISTS (
	SELECT 1
	FROM ccGalateaOperations
	WHERE OperationId = 176
)
BEGIN
	INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
	VALUES (176, 'Desasignar calificaci�n de agente virtual', 'Unassign virtual agent disposition', 'Cancelar atribui��o de classifica��o de agente virtual');
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
GO