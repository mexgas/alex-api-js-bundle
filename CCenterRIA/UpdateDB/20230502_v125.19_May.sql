/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 19
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci?n para cuando pasamos a una nueva versi?n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN

    BEGIN TRY
        -------------------------------------------- BEGIN JONATHAN RAMIREZ (ACTIVITY LOG)------------------------------
        SET @process = '1 - Insert New Modules Areas, Operations and Relation with this module'
        SET @sql = '
IF NOT EXISTS(SELECT * FROM ccGalateaModules WHERE ModuleId = 3) INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) VALUES (3, ''Áreas'', ''Areas'', ''Áreas'');

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 17) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (17, ''Crear área'', ''Create area'', ''Criar área'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 17);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 18) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (18, ''Editar área'', ''Edit area'', ''Editar área'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 18);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 19) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (19, ''Eliminar área'', ''Delete area'', ''Excluir área'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 19);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 20) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (20, ''Crear grupo de trabajo'', ''Create workgroup'', ''Criar grupo de trabalho'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 20);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 21) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (21, ''Eliminar grupo de trabajo'', ''Delete workgroup'', ''Excluir grupo de trabalho'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 21);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 22) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (22, ''Crear agente'', ''Create agent'', ''Criar agente'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 22);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 23) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (23, ''Asignar agente'', ''Assign agent'', ''Atribuir agente'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 23);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 24) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (24, ''Desasignar agente'', ''Unassign agent'', ''Cancelar atribuição de agente'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 24);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 25) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (25, ''Editar agente'', ''Edit agent'', ''Editar agente'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 25);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 26) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (26, ''Cambiar contraseña de agente'', ''Reset agent''''''''s password'', ''Alterar senha de agente'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 26);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 27) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (27, ''Cambiar agente de área'', ''Change agent''''''''s area'', ''Mudar agente de área'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 27);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 28) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (28, ''Eliminar agente'', ''Delete agent'', ''Excluir agente'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 28);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 29) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (29, ''Crear administrador'', ''Create administrator'', ''Criar administrador'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 29);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 30) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (30, ''Asignar administrador'', ''Assign administrator'', ''Atribuir administrador'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 30);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 31) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (31, ''Desasignar administrador'', ''Unassign administrator'', ''Cancelar atribuição de administrador'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 31);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 32) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (32, ''Editar administrador'', ''Edit administrator'', ''Editar administrador'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 32);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 33) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (33, ''Cambiar contraseña de administrador'', ''Reset administrator''''''''s password'', ''Alterar senha de administrador'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 33);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 34) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (34, ''Cambiar administrador de área'', ''Change administrator''''''''s area'', ''Mudar administrador de área'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 34);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 35) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (35, ''Eliminar administrador'', ''Delete administrator'', ''Excluir administrador'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 35);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 36) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (36, ''Asignar campaña'', ''Assign campaign'', ''Atribuir campanha'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 36);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 40) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (40, ''Crear campaña (WhatsApp de entrada)'', ''Create campaign (inbound WhatsApp)'', ''Criar campanha (WhatsApp de entrada)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 40);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 41) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (41, ''Eliminar campaña (WhatsApp de entrada)'', ''Delete campaign (inbound WhatsApp)'', ''Excluir campanha (WhatsApp de entrada)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 41);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 42) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (42, ''Crear campaña (llamada de salida)'', ''Create campaign (outbound call)'', ''Criar campanha (chamada de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 42);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 43) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (43, ''Eliminar campaña (llamada de salida)'', ''Delete campaign (outbound call)'', ''Excluir campanha (chamada de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 43);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 44) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (44, ''Crear campaña (llamada de salida VP)'', ''Create campaign (preview outbound call)'', ''Criar campanha (chamada de saída V)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 44);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 45) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (45, ''Eliminar campaña (llamada de salida VP)'', ''Delete campaign (preview outbound call)'', ''Excluir campanha (chamada de saída V)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 45);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 46) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (46, ''Crear campaña (WhatsApp de salida)'', ''Create campaign (outbound WhatsApp)'', ''Criar campanha (WhatsApp de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 46);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 47) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (47, ''Eliminar campaña (WhatsApp de salida)'', ''Delete campaign (outbound WhatsApp)'', ''Excluir campanha (WhatsApp de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 47);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 48) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (48, ''Crear campaña (llamada de salida IA)'', ''Create campaign (AI outbound call)'', ''Criar campanha (chamada de saída IA)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 48);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 49) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (49, ''Eliminar campaña (llamada de salida IA)'', ''Delete campaign (AI outbound call)'', ''Excluir campanha (chamada de saída IA)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 49);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 50) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (50, ''Crear campaña (SMS de salida)'', ''Create campaign (outbound SMS)'', ''Criar campanha (SMS de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 50);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 51) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (51, ''Eliminar campaña (SMS de salida)'', ''Delete campaign (outbound SMS)'', ''Excluir campanha (SMS de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 51);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 52) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (52, ''Editar campaña (llamada de entrada)'', ''Edit campaign (inbound call)'', ''Editar campanha (chamada de entrada)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 52);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 53) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (53, ''Editar campaña (WhatsApp de entrada)'', ''Edit campaign (inbound WhatsApp)'', ''Editar campanha (WhatsApp de entrada)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 53);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 54) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (54, ''Editar campaña (llamada de salida)'', ''Edit campaign (outbound call)'', ''Editar campanha (chamada de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 54);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 55) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (55, ''Editar campaña (llamada de salida VP)'', ''Edit campaign (preview outbound call)'', ''Editar campanha (chamada de saída V)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 55);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 56) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (56, ''Editar campaña (WhatsApp de salida)'', ''Edit campaign (outbound WhatsApp)'', ''Editar campanha (WhatsApp de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 56);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 57) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (57, ''Editar campaña (llamada de salida IA)'', ''Edit campaign (AI outbound call)'', ''Editar campanha (chamada de saída IA)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 57);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 58) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (58, ''Editar campaña (SMS de salida)'', ''Edit campaign (outbound SMS)'', ''Editar campanha (SMS de saída)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 58);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 59) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (59, ''Desasignar campaña'', ''Unassign campaign'', ''Cancelar atribuição de campanha'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 59);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 60) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (60, ''Crear campaña (llamada de entrada)'', ''Create campaign (inbound call)'', ''Criar campanha (chamada de entrada)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 60);
END
IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 61) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (61, ''Eliminar campaña (llamada de entrada)'', ''Delete campaign (inbound call)'', ''Excluir campanha (chamada de entrada)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 61);
END
        '
        EXEC(@sql)

        SET @process = '2 - Insert Identifiers in ccGalateaIdentifiers'
        SET @sql = '
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_NAME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_NAME'', ''Nombre'', ''Name'', ''Nome'')
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&SET_CAMPAIGN'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&SET_CAMPAIGN'', ''Campaña predeterminada'', ''Default campaign'', ''Campanha padrão'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&SET_MAX_CHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&SET_MAX_CHATS'', ''Conversaciones de chat por agente'', ''Chat conversations per agent'', ''Conversas de chat por agente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&SET_MAX_MAILS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&SET_MAX_MAILS'', ''Conversaciones de correo por agente'', ''Email conversations per agent'', ''Conversas de e-mail por agente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&SET_MAX_TWITTER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&SET_MAX_TWITTER'', ''Conversaciones de Twitter por agente'', ''Twitter conversations per agent'', ''Conversas de Twitter por agente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_NAME_USER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_NAME_USER'', ''Nombre'', ''Name'', ''Nome'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_MIDDLE_NAME_USER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_MIDDLE_NAME_USER'', ''Segundo nombre'', ''Middle name'', ''Segundo nome'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_LAST_NAME_USER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_LAST_NAME_USER'', ''Apellido'', ''Last name'', ''Sobrenome'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_GENDER_USER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_GENDER_USER'', ''Género'', ''Gender'', ''Gênero'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_GENDER_USER_M'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_GENDER_USER_M'', ''Masculino'', ''Male'', ''Masculino'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_GENDER_USER_F'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_GENDER_USER_F'', ''Femenino'', ''Female'', ''Feminino'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&COMMON_NONE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&COMMON_NONE'', ''Ninguna'', ''None'', ''Nenhuma'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&CHANGE_USER_AREA'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&CHANGE_USER_AREA'', ''Área'', ''Area'', ''Área'');

----Create campaign (inbound call)****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_MAX_WAIT_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_MAX_WAIT_TIME'', ''Tiempo máximo de espera'', ''Maximum wait time'', ''Tempo máximo de espera'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_DESTINATION_WAIT_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_DESTINATION_WAIT_TIME'', ''Destino (tiempo de espera excedido)'', ''Destination (wait time exceeded)'', ''Destino (tempo de espera excedido)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_MAX_CALLS_QUEUE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_MAX_CALLS_QUEUE'', ''Número máximo en espera'', ''Maximum calls in queue'', ''Número máximo na fila'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_DESTINATION_QUEUE_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_DESTINATION_QUEUE_TIME'', ''Destino (número en espera excedido)'', ''Destination (queue limit exceeded)'', ''Destino (limite da fila excedido)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_DESTINATION_OUT_SERVIVE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_DESTINATION_OUT_SERVIVE'', ''Destino (fuera de servicio)'', ''Destination (out of service)'', ''Destino (fora de serviço)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_DESTINATION_OUT_SCHEDULE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_DESTINATION_OUT_SCHEDULE'', ''Destino (fuera de horario)'', ''Destination (out of schedule)'', ''Destino (fora de horário)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_FORWADING_PREFIX'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_FORWADING_PREFIX'', ''Prefijo de desvío'', ''Call forwarding prefix'', ''Prefixo de encaminhamento'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_PLAY_QUEUE_AUDIO'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_PLAY_QUEUE_AUDIO'', ''Reproducir opción de cola virtual'', ''Play virtual queue audio'', ''Reproduzir áudio de fila virtual'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_PLAY_QUEUE_ORDER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_PLAY_QUEUE_ORDER'', ''Reproducir orden en cola'', ''Play queue order audio'', ''Reproduzir áudio de ordem da fila'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_STOP_RECORDING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_STOP_RECORDING'', ''Detener grabación después de transferir'', ''Stop recording after transfer'', ''Parar de gravar depois de transferir'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_WRAP_UP_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_WRAP_UP_TIME'', ''Tiempo de notas'', ''Wrap-up time'', ''Tempo de notas'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_SHOW_DISPOSITIONS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_SHOW_DISPOSITIONS'', ''Mostrar calificaciones'', ''Show dispositions'', ''Mostrar classificações'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_KEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_CALL_KEY'', ''Editar clave de llamada'', ''Edit call key'', ''Editar chave de chamada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_ANI_FORWARDING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_ANI_FORWARDING'', ''ANI (para desvío)'', ''ANI (on call forwarding)'', ''ANI (para encaminhamento)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CONDUCT_SURVEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_CONDUCT_SURVEY'', ''Aplicar encuesta'', ''Conduct survey'', ''Executar pesquisa'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CONDUCT_CALLBACK_SURVEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_CONDUCT_CALLBACK_SURVEY'', ''Aplicar encuesta reprogramada'', ''Conduct callback survey'', ''Executar pesquisa reagendada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_RECEIVE_DTMF_TONES'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_RECEIVE_DTMF_TONES'', ''Recibir tonos DTMF'', ''Receive DTMF tones'', ''Receber tons DTMF'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_BACK'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_CALL_BACK'', ''Devolver llamada (Reminder)'', ''Call back (Reminder)'', ''Retornar chamada (Reminder)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_RECORD_ON_HOLD'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_RECORD_ON_HOLD'', ''Grabar llamada en espera'', ''Record call on hold'', ''Gravar chamada em espera'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_ASSOCIATED_CAMPAIGN'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_ASSOCIATED_CAMPAIGN'', ''Campaña asociada'', ''Associated campaign'', ''Campanha associada'');

----Create campaign (inbound whatsapp)****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_ASSOCIATED_PHONE_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_ASSOCIATED_PHONE_WHATS'', ''Teléfono asociado'', ''Associated phone number'', ''Telefone associado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_MAX_ANSWER_AGENT_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_MAX_ANSWER_AGENT_WHATS'', ''Tiempo máximo de respuesta (agente) (min)'', ''Maximum answer time (agent) (min)'', ''Tempo máximo de resposta (agente) (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_MAX_ANSWER_CONTACT_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_MAX_ANSWER_CONTACT_WHATS'', ''Tiempo máximo de respuesta (contacto) (min)'', ''Maximum answer time (contact) (min)'', ''Tempo máximo de resposta (contato) (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_ATTACH_FILES_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_ATTACH_FILES_WHATS'', ''Adjuntar archivos'', ''Attach files'', ''Anexar arquivos'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_WRAP_UP_TIME_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_WRAP_UP_TIME_WHATS'', ''Tiempo de notas'', ''Wrap-up time'', ''Tempo de notas'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_WRAP_ON_DIPOSITION_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_WRAP_ON_DIPOSITION_WHATS'', ''Finalizar tiempo de notas al calificar'', ''Exit wrap-up status on disposition'', ''Terminar o tempo de notas ao atribuir classificação'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_SHOW_DISPOSITIONS_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_SHOW_DISPOSITIONS_WHATS'', ''Mostrar calificaciones'', ''Show dispositions'', ''Mostrar classificações'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_ASSOCIATED_CAMPAIGN_WHATS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_ASSOCIATED_CAMPAIGN_WHATS'', ''Campaña asociada'', ''Associated campaign'', ''Campanha associada'');

----Crear campaña (llamada de salida)****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MAX_DIALING_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MAX_DIALING_TIME'', ''Tiempo máximo de marcación'', ''Maximum dialing time'', ''Tempo máximo de discagem'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_DIAL_BEFORE_WRAP_UP'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_DIAL_BEFORE_WRAP_UP'', ''Marcar antes de fin de notas'', ''Dial before wrap-up timeout'', ''Discar antes do fim de notas'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_RETRIES_NOT_ANSWERED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_RETRIES_NOT_ANSWERED'', ''Reintentos en no contestadas'', ''Retries on not answered'', ''Tentativas em não atendidas'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTERVAL_NOT_ANSWERED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_INTERVAL_NOT_ANSWERED'', ''Intervalo en no contestadas (min)'', ''Interval on not answered (min)'', ''Intervalo em não atendidas (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_RETRIES_BUSY_LINE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_RETRIES_BUSY_LINE'', ''Reintentos en ocupado'', ''Retries on busy line'', ''Tentativas em ocupado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTERVAL_BUSY_LINE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_INTERVAL_BUSY_LINE'', ''Intervalo en ocupado (min)'', ''Interval on busy line (min)'', ''Intervalo em ocupado (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_RETRIES_FAX_MODEM'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_RETRIES_FAX_MODEM'', ''Reintentos en fax/módem'', ''Retries on fax/modem'', ''Tentativas em fax/modem'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTERVAL_FAX_MODEM'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_INTERVAL_FAX_MODEM'', ''Intervalo en fax/módem (min)'', ''Interval on fax/modem (min)'', ''Intervalo em fax/modem (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_RETRIES_AM_VOICEMAIL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_RETRIES_AM_VOICEMAIL'', ''Reintentos en máquina/buzón'', ''Retries on AM/voicemail'', ''Tentativas em s. eletrônica/c. postal'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTERVAL_AM_VOICEMAIL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_INTERVAL_AM_VOICEMAIL'', ''Intervalo en máquina/buzón (min)'', ''Interval on AM/voicemail (min)'', ''Intervalo em s. eletrônica/c. postal (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTERVAL_CANCELLED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_INTERVAL_CANCELLED'', ''Intervalo de reintentos en canceladas (min)'', ''Retry interval on cancelled (min)'', ''Intervalo de tentativas em canceladas (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ANI'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ANI'', ''ANI'', ''ANI'', ''ANI'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_DIALING_PREFIX_PREDICTIVE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_DIALING_PREFIX_PREDICTIVE'', ''Prefijo de marcación predictiva'', ''Dialing prefix (predictive calls)'', ''Prefixo de discagem preditiva'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_DIALING_PREFIX_MANUAL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_DIALING_PREFIX_MANUAL'', ''Prefijo de marcación (llamada manual)'', ''Dialing prefix (manual calls)'', ''Prefixo de discagem (chamada manual)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_DIALING_PREFIX_TRANFERS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_DIALING_PREFIX_TRANFERS'', ''Prefijo de marcación (transferencia)'', ''Dialing prefix (transfers)'', ''Prefixo de discagem (transferência)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_AUTO_CALLBACK_INTERVAL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_AUTO_CALLBACK_INTERVAL'', ''Intervalo de devolución automática de llamada (min)'', ''Automatic callback interval (min)'', ''Intervalo de retorno automático de chamada (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MAX_CALLS_QUEUE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MAX_CALLS_QUEUE'', ''Número máximo en cola'', ''Maximum calls in queue'', ''Número máximo em fila'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_DIALING_ORDER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_DIALING_ORDER'',''Orden de marcación'',''Dialing order'',''Ordem de discagem'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ANSWER_MACHINE_DETC'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ANSWER_MACHINE_DETC'',''Detección de máquina contestadora'',''Answering machine detection'',''Detecção de secretária eletrônica'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ANI_MODE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ANI_MODE'',''Modalidad de ANI'',''ANI mode'',''Modalidade de ANI'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ANI_LIST'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ANI_LIST'',''Lista de ANI'',''ANI list'',''Lista de ANI'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_SELECT_ANI_ON_DIALING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_SELECT_ANI_ON_DIALING'',''Seleccionar ANI en marcación manual'',''Select ANI on manual dialing'',''Selecionar ANI em discagem manual'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_DIALING_MODE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_DIALING_MODE'',''Modo de marcación'',''Dialing mode'',''Modo de discagem'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MANUAL_DIALING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MANUAL_DIALING'',''Marcación manual'',''Manual dialing'',''Discagem manual'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MANUAL_DIALING_ON_CHAT'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MANUAL_DIALING_ON_CHAT'',''Marcación manual en chat'',''Manual dialing on chat'',''Discagem manual em chat'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_TIME_ZONE_VALIDATION_MANUAL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_TIME_ZONE_VALIDATION_MANUAL'',''Validación de zona horaria en marcación manual'',''Time zone validation on manual dialing'',''Validação de fuso horário em discagem manual'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTENSIVE_DIALING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_INTENSIVE_DIALING'',''Marcación intensiva'',''Intensive dialing'',''Discagem intensiva'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_CALLBACK_EXCLUSIVE_AGENT'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_CALLBACK_EXCLUSIVE_AGENT'',''Devolución de llamada (agente exclusivo)'',''Callback (exclusive agent)'',''Retorno de chamada (agente exclusivo)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_VOIEMAIL_DETECTION'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_VOIEMAIL_DETECTION'',''Detección de buzón de voz'',''Voicemail detection'',''Detecção de caixa postal'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_CALLBACK_FAILED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_CALLBACK_FAILED'',''Devolución de llamada (evento fallido)'',''Callback (failed attempt)'',''Retorno de chamada (tentativa com falha)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_EXIT_ASSISTED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_EXIT_ASSISTED'',''Salir del modo de marcación asistida'',''Exit assisted dialing mode'',''Sair do modo de discagem assistida'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_WRAP_UP_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_WRAP_UP_TIME'',''Tiempo de notas'',''Wrap-up time'',''Tempo de notas'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_SHOW_DISPOSITIONS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_SHOW_DISPOSITIONS'',''Mostrar calificaciones'',''Show dispositions'',''Mostrar classificações'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_EDIT_CALL_KEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_EDIT_CALL_KEY'',''Editar clave de llamada'',''Edit call key'',''Editar chave de chamada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_LISTEN_TONE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_LISTEN_TONE'',''Escuchar tonos en llamada manual'',''Listen to dial tone on manual call'',''Escutar tons em chamada manual'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_STOP_RECORDING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_STOP_RECORDING'',''Detener grabación después de transferir'',''Stop recording after transfer'',''Parar de gravar depois de transferir'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_LEAVE_PRERECORDED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_LEAVE_PRERECORDED'',''Dejar mensaje pregrabado manualmente'',''Leave prerecorded message manually'',''Deixar mensagem gravada manualmente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_RECORD_ON_HOLD'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_RECORD_ON_HOLD'',''Grabar llamada en espera'',''Record call on hold'',''Gravar chamada em espera'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_CONDUCT_SURVEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_CONDUCT_SURVEY'',''Aplicar encuesta'',''Conduct survey'',''Executar pesquisa'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_CONDUCT_CALLBACK_SURVEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_CONDUCT_CALLBACK_SURVEY'',''Aplicar encuesta reprogramada'',''Conduct callback survey'',''Executar pesquisa reagendada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_RECEIVE_DTMF'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_RECEIVE_DTMF'',''Recibir tonos DTMF'',''Receive DTMF tones'',''Receber tons DTMF'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_SIP_IDENTIFIER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_SIP_IDENTIFIER'',''Identificador SIP personalizado'',''Custom SIP identifier'',''Identificador SIP personalizado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ADD_VARIABLES_SIP'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ADD_VARIABLES_SIP'',''Añadir variables a identificador SIP personalizado'',''Add variables to custom SIP identifier'',''Adicionar variáveis à identificador SIP personalizado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ANI_TRANSFERS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ANI_TRANSFERS'',''ANI (para transferencia)'',''ANI (on transfer)'',''ANI (para transferência)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_ASSOCIATED_CAMP'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_ASSOCIATED_CAMP'',''Campaña asociada'',''Associated campaign'',''Campanha associada'');

----PREVIEW TAGS*****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MAXIMUN_PREVIEW'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MAXIMUN_PREVIEW'',''Tiempo máximo de previsualización'',''Maximum preview time'',''Tempo máximo de visualização'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MAXIMUN_ASSIGNMENT_ATTEMPS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MAXIMUN_ASSIGNMENT_ATTEMPS'',''Número máximo de asignaciones'',''Maximum assignment attempts'',''Número máximo de atribuições'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_MAXIMUN_UNASSIGNMENT_ATTEMPS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_MAXIMUN_UNASSIGNMENT_ATTEMPS'',''Número máximo de desasignaciones'',''Maximum unassignment attempts'',''Limite de cancelamento de atribuição'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_UNASSIGN_RECORDS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_UNASSIGN_RECORDS'',''Desasignar registros'',''Unassign records'',''Cancelar atribuição de registros'');

---OUT WHATSAPP TAGS****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_WHATS_ASSOCIATED_PHONE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_WHATS_ASSOCIATED_PHONE'',''Teléfono asociado'',''Associated phone number'',''Telefone associado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_WHATS_MAX_ANSWER_AGENT'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_WHATS_MAX_ANSWER_AGENT'',''Tiempo máximo de respuesta (agente) (min)'',''Maximum answer time (agent) (min)'',''Tempo máximo de resposta (agente) (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_WHATS_MAX_ANSWER_CONTACT'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_WHATS_MAX_ANSWER_CONTACT'',''Tiempo máximo de respuesta (contacto) (min)'',''Maximum answer time (contact) (min)'',''Tempo máximo de resposta (contato) (min)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_WHATS_ATTACH_FILES'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_WHATS_ATTACH_FILES'',''Adjuntar archivos'',''Attach files'',''Anexar arquivos'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_WHATS_EXIT_ASSISTED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_WHATS_EXIT_ASSISTED'',''Finalizar tiempo de notas al calificar'',''Exit wrap-up status on disposition'',''Terminar o tempo de notas ao atribuir classificação'');

---OUT SMS TAGS****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_SMS_START_CAMP_AUTO'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_SMS_START_CAMP_AUTO'',''Iniciar campaña automáticamente'',''Start campaign automatically'',''Iniciar a campanha automaticamente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_SMS_MESSAGING_ORDER'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_SMS_MESSAGING_ORDER'',''Orden de envío'',''Messaging order'',''Ordem de envio'');


---EDITAR LLAMADA ENTRADA
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_EDIT_NAME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_CALL_EDIT_NAME'',''Nombre'',''Name'',''Nome'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_EDIT_ICON'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''IN_CALL_EDIT_ICON'',''Ícono'',''Icon'',''Ícone'');

---EDITAR LLAMADA SALIDA
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_CALL_EDIT_NAME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_CALL_EDIT_NAME'',''Nombre'',''Name'',''Nome'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''OUT_CALL_EDIT_ICON'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''OUT_CALL_EDIT_ICON'',''Ícono'',''Icon'',''Ícone'');

----Common Tags****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_VOICE_MAIL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_VOICE_MAIL'', ''Buzón de voz'', ''Voicemail'', ''Caixa postal'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ENABLED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ENABLED'', ''Habilitado'', ''Enabled'', ''Ativado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DISABLED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DISABLED'', ''Deshabilitado'', ''Disabled'', ''Desativado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_CALLBACK'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_CALLBACK'', ''Reprogramada'', ''Callback'', ''Reagendada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_IMMEDIATE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_IMMEDIATE'', ''Inmediata'', ''Immediate'', ''Imediata'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ASCENDING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ASCENDING'', ''Ascendente'', ''Ascending'', ''Crescente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DESCENDING'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DESCENDING'', ''Descendente'', ''Descending'', ''Decrescente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_BASIC'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_BASIC'', ''Básica'', ''Basic'', ''Básica'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_LIGHT'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_LIGHT'', ''Ligera'', ''Light'', ''Leve'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_MODERATE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_MODERATE'', ''Moderada'', ''Moderate'', ''Moderada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_HIGH'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_HIGH'', ''Alta'', ''High'', ''Alta'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ANI_LOCAL'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ANI_LOCAL'', ''ANI local'', ''Local ANI'', ''ANI local'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ANI_ROTATIVE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ANI_ROTATIVE'', ''ANI rotativo'', ''Rotative ANI'', ''ANI rotativo'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ANI_ROTATIVE_REG'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ANI_ROTATIVE_REG'', ''ANI rotativo regionalizado'', ''Regional rotative ANI'', ''ANI rotativo regional'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ANI_ROTATIVE_SMART'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ANI_ROTATIVE_SMART'', ''ANI rotativo inteligente'', ''Smart rotative ANI'', ''ANI rotativo inteligente'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_PREDICTIVE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_PREDICTIVE'', ''Predictiva'', ''Predictive'', ''Preditiva'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_PROGRESIVE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_PROGRESIVE'', ''Progresiva'', ''Progressive'', ''Progressiva'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ASSISTED'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ASSISTED'', ''Asistida'', ''Assisted'', ''Assistida'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_VIA_KEYPAD_LOG'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_VIA_KEYPAD_LOG'', ''Vía teclado e historial'', ''Via keypad and log'', ''Via teclado e histórico'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_VIA_CALLS_LOG'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_VIA_CALLS_LOG'', ''Vía historial de llamadas'', ''Via calls log'', ''Via histórico de chamadas'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_VIA_CALLS_LOG'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_VIA_CALLS_LOG'', ''Vía dato en teclado'', ''Via data in keypad'', ''Via dado no teclado'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_CAMPAIGN_ID'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_CAMPAIGN_ID'', ''ID de campaña'', ''Campaign ID'', ''ID de campanha'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_CALL_KEY'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_CALL_KEY'', ''Clave de llamada'', ''Call key'', ''Chave de chamada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_DATA_1'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_DATA_1'', ''Dato 1'', ''Data 1'', ''Dado 1'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_DATA_2'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_DATA_2'', ''Dato 2'', ''Data 2'', ''Dado 2'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_DATA_3'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_DATA_3'', ''Dato 3'', ''Data 3'', ''Dado 3'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_DATA_4'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_DATA_4'', ''Dato 4'', ''Data 4'', ''Dado 4'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_DATA_5'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_DATA_5'', ''Dato 5'', ''Data 5'', ''Dado 5'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_PBX_IP_ADDRESS'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_PBX_IP_ADDRESS'', ''Dirección IP de PBX'', ''PBX IP address'', ''Endereço IP de PBX'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_CALL_ID'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_CALL_ID'', ''ID de llamada'', ''Call ID'', ''ID de chamada'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_SIP_DATE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_SIP_DATE'', ''Fecha'', ''Date'', ''Data'');

----Common Date Tags****
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DATE_1'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DATE_1'', ''Fecha de inicio y fin (horario 1)'', ''Start and end date (schedule 1)'', ''Data de início e término (horário 1)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DATE_2'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DATE_2'', ''Fecha de inicio y fin (horario 2)'', ''Start and end date (schedule 2)'', ''Data de início e término (horário 2)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DATE_3'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DATE_3'', ''Fecha de inicio y fin (horario 3)'', ''Start and end date (schedule 3)'', ''Data de início e término (horário 3)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DATE_4'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DATE_4'', ''Fecha de inicio y fin (horario 4)'', ''Start and end date (schedule 4)'', ''Data de início e término (horário 4)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DATE_5'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DATE_5'', ''Fecha de inicio y fin (horario 5)'', ''Start and end date (schedule 5)'', ''Data de início e término (horário 5)'');

IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ADD_SCHEDULE_1'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ADD_SCHEDULE_1'', ''Añadir horario (horario 1)'', ''Add schedule (schedule 1)'', ''Adicionar horário (horário 1)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ADD_SCHEDULE_2'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ADD_SCHEDULE_2'', ''Añadir horario (horario 2)'', ''Add schedule (schedule 2)'', ''Adicionar horário (horário 2)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ADD_SCHEDULE_3'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ADD_SCHEDULE_3'', ''Añadir horario (horario 3)'', ''Add schedule (schedule 3)'', ''Adicionar horário (horário 3)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ADD_SCHEDULE_4'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ADD_SCHEDULE_4'', ''Añadir horario (horario 4)'', ''Add schedule (schedule 4)'', ''Adicionar horário (horário 4)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_ADD_SCHEDULE_5'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_ADD_SCHEDULE_5'', ''Añadir horario (horario 5)'', ''Add schedule (schedule 5)'', ''Adicionar horário (horário 5)'');

IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DELETE_SCHEDULE_1'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DELETE_SCHEDULE_1'', ''Eliminar horario (horario 1)'', ''Delete schedule (schedule 1)'', ''Excluir horário (horário 1)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DELETE_SCHEDULE_2'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DELETE_SCHEDULE_2'', ''Eliminar horario (horario 2)'', ''Delete schedule (schedule 2)'', ''Excluir horário (horário 2)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DELETE_SCHEDULE_3'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DELETE_SCHEDULE_3'', ''Eliminar horario (horario 3)'', ''Delete schedule (schedule 3)'', ''Excluir horário (horário 3)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DELETE_SCHEDULE_4'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DELETE_SCHEDULE_4'', ''Eliminar horario (horario 4)'', ''Delete schedule (schedule 4)'', ''Excluir horário (horário 4)'');
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DELETE_SCHEDULE_5'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''COMMON_DELETE_SCHEDULE_5'', ''Eliminar horario (horario 5)'', ''Delete schedule (schedule 5)'', ''Excluir horário (horário 5)'');

--ZIPCODE
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''SETTINGS_CHANGED_AREAS_ZIP'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''SETTINGS_CHANGED_AREAS_ZIP'', ''Validar zona horaria por código postal'', ''Validate time zone by ZIP code'', ''Validar fuso horário por CEP'');
        '
        EXEC(@sql)

        SET @process = '3 - Create Table relationTableColumnIdentifiers and Insert Relation Table Column - Identifier'
        SET @sql = '
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name=''relationTableColumnIdentifiers'') BEGIN

CREATE TABLE relationTableColumnIdentifiers(
    Identifiers VARCHAR(255),
    tableName VARCHAR(255), 
    colunName VARCHAR(255)
);

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&EDIT_NAME'', ''cccamps'', ''cam_description'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&EDIT_NAME'', ''ccRIACat_Areas'', ''AreaName'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&SET_MAX_CHATS'', ''ccRIACat_Areas'', ''maxChats'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&SET_MAX_MAILS'', ''ccRIACat_Areas'', ''maxMails'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&SET_MAX_TWITTER'', ''ccRIACat_Areas'', ''maxTweets'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&SET_CAMPAIGN'', ''ccRIACat_Areas'', ''defCampaing'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&EDIT_NAME_USER'', ''ccUsers'', ''Nombres'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&EDIT_MIDDLE_NAME_USER'', ''ccUsers'', ''ApellidoMaterno'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&EDIT_LAST_NAME_USER'', ''ccUsers'', ''ApellidoPaterno'')

INSERT INTO relationTableColumnIdentifiers
VALUES (''T&EDIT_GENDER_USER'', ''ccUsers'', ''Sexo'')

----ccInbound ****

INSERT INTO relationTableColumnIdentifiers VALUES (''IN_MAX_WAIT_TIME'', ''ccInbound'', ''tMaxWaitCall'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_DESTINATION_WAIT_TIME'', ''ccInbound'', ''tel_maxwait'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_MAX_CALLS_QUEUE'', ''ccInbound'', ''nMaxQue'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_DESTINATION_QUEUE_TIME'', ''ccInbound'', ''tel_maxqueue'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_DESTINATION_OUT_SERVIVE'', ''ccInbound'', ''tel_outservice'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_DESTINATION_OUT_SCHEDULE'', ''ccInbound'', ''tel_noct'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_FORWADING_PREFIX'', ''ccInbound'', ''dialPrefixOverflow'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_PLAY_QUEUE_AUDIO'', ''ccInbound'', ''tMaxQueueCallBack'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_PLAY_QUEUE_ORDER'', ''ccInbound'', ''queuePosition'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_STOP_RECORDING'', ''ccInbound'', ''stopRecording'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_WRAP_UP_TIME'', ''ccInbound'', ''tNotas'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_SHOW_DISPOSITIONS'', ''ccInbound'', ''ShowCalifWnd'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_CALL_KEY'', ''ccInbound'', ''editableCallKey'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_ANI_FORWARDING'', ''ccInbound'', ''callerIdDesc'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_CONDUCT_SURVEY'', ''ccInbound'', ''callBackSurveyAgent'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_CONDUCT_CALLBACK_SURVEY'', ''ccInbound'', ''callBackSurveyClient'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_RECEIVE_DTMF_TONES'', ''ccInbound'', ''editableDtmf'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_CALL_BACK'', ''ccInbound'', ''addDataCallBackReminder'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_RECORD_ON_HOLD'', ''ccInbound'', ''recordHold'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_CALL_EDIT_NAME'', ''ccInbound'', ''descripcion'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_WRAP_ON_DIPOSITION_WHATS'', ''ccInbound'', ''ExitWrapUpDisposition'')

INSERT INTO relationTableColumnIdentifiers VALUES (''IN_ASSOCIATED_PHONE_WHATS'', ''contactMeanIn'', ''conexionInfo'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_MAX_ANSWER_AGENT_WHATS'', ''contactMeanIn'', ''closeConversationTime'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_MAX_ANSWER_CONTACT_WHATS'', ''contactMeanIn'', ''answerTimeoutClient'')
INSERT INTO relationTableColumnIdentifiers VALUES (''IN_ATTACH_FILES_WHATS'', ''contactMeanIn'', ''allowFileAttachments'')


--ccCamps****
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_MAX_DIALING_TIME'',''ccCamps'',''cam_tNoContesta'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_DIAL_BEFORE_WRAP_UP'',''ccCamps'',''tDialonWrapUp'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_RETRIES_NOT_ANSWERED'',''ccCamps'',''cam_NoInt_nocontesto'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_INTERVAL_NOT_ANSWERED'',''ccCamps'',''cam_inter_nocontesto'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_RETRIES_BUSY_LINE'',''ccCamps'',''cam_NoInt_ocupado'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_INTERVAL_BUSY_LINE'',''ccCamps'',''cam_inter_ocupado'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_RETRIES_FAX_MODEM'',''ccCamps'',''cam_NoInt_fax'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_INTERVAL_FAX_MODEM'',''ccCamps'',''cam_inter_fax'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_RETRIES_AM_VOICEMAIL'',''ccCamps'',''cam_NoInt_graba'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_INTERVAL_AM_VOICEMAIL'',''ccCamps'',''CamInterRecord'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_INTERVAL_CANCELLED'',''ccCamps'',''cam_inter_cancelled'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_ANI'',''ccCamps'',''ANI'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_DIALING_PREFIX_PREDICTIVE'',''ccCamps'',''dialPrefix'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_DIALING_PREFIX_MANUAL'',''ccCamps'',''dialPrefixMan'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_DIALING_PREFIX_TRANFERS'',''ccCamps'',''dialPrefixXfe'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_AUTO_CALLBACK_INTERVAL'',''ccCamps'',''t_autoCB'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_MAX_CALLS_QUEUE'',''ccCamps'',''cam_maxqueue'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_DIALING_ORDER'',''ccCamps'',''dialOrder'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_ANSWER_MACHINE_DETC'',''ccCamps'',''detectAnswerMachine'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_ANI_MODE'',''ccCamps'',''rotativeAlgo'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_ANI_LIST'',''ccCamps'',''id_anilist'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_SELECT_ANI_ON_DIALING'',''ccCamps'',''selectRotativeANI'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_DIALING_MODE'',''ccCamps'',''progDial'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_MANUAL_DIALING'',''ccCamps'',''cam_ModoManual'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_MANUAL_DIALING_ON_CHAT'',''ccCamps'',''manualCallOnChat'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_TIME_ZONE_VALIDATION_MANUAL'',''ccCamps'',''timeZoneRule'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_INTENSIVE_DIALING'',''ccCamps'',''iTipoDial'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_CALLBACK_EXCLUSIVE_AGENT'',''ccCamps'',''excCallBack'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_VOIEMAIL_DETECTION'',''ccCamps'',''detectVoiceMail'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_CALLBACK_FAILED'',''ccCamps'',''abandonCallback'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_EXIT_ASSISTED'',''ccCamps'',''exitAssisted'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_WRAP_UP_TIME'',''ccCamps'',''cam_tnotas'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_SHOW_DISPOSITIONS'',''ccCamps'',''cam_ShowCalifWnd'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_EDIT_CALL_KEY'',''ccCamps'',''editableCallKey'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_STOP_RECORDING'',''ccCamps'',''stopRecording'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_LEAVE_PRERECORDED'',''ccCamps'',''leaveRecMessage'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_CONDUCT_SURVEY'',''ccCamps'',''callBackSurveyAgent'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_CONDUCT_CALLBACK_SURVEY'',''ccCamps'',''CallBackSurveyClient'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_RECEIVE_DTMF'',''ccCamps'',''funcEspDtmf'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_SIP_IDENTIFIER'',''ccCamps'',''sipHdrFormat'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_ANI_TRANSFERS'',''ccCamps'',''callerIdDesc'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_RECORD_ON_HOLD'',''ccCamps'',''recordHold'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_LISTEN_TONE'',''ccCamps'',''listenManualCall'');

----ccCamps Preview*****
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_WHATS_ASSOCIATED_PHONE'',''contactMeanOut'',''conexionInfo'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_WHATS_MAX_ANSWER_AGENT'',''contactMeanOut'',''closeConversationTime'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_WHATS_MAX_ANSWER_CONTACT'',''contactMeanOut'',''answerTimeoutClient'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_WHATS_ATTACH_FILES'',''contactMeanOut'',''allowFileAttachments'');

----contactMeanOut*****
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_UNASSIGN_RECORDS'',''ccCamps'',''previewDiscard'');

----ccCamps SMS*****
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_SMS_START_CAMP_AUTO'',''ccCamps'',''autoStart'');
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_SMS_MESSAGING_ORDER'',''ccCamps'',''messagingOrder'');

----ccCamps EDIT****
INSERT INTO relationTableColumnIdentifiers VALUES (''OUT_CALL_EDIT_NAME'',''ccCamps'',''cam_descripcion'');

--ZIPCODE
INSERT INTO relationTableColumnIdentifiers VALUES (''SETTINGS_CHANGED_AREAS_ZIP'',''ccCampsExtend'',''zipCodeSchedule'');
END
        '
        EXEC(@sql)


SET @process = '4 - Create Table sipDataIdentifier and Insert KEY - VALUE'
        SET @sql = '
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name=''sipDataIdentifier'') BEGIN

CREATE TABLE sipDataIdentifier(
    dataId VARCHAR(30) PRIMARY KEY NOT NULL,
    identifier VARCHAR(MAX)
)

INSERT INTO sipDataIdentifier (dataId, identifier) 
VALUES  (''CAMID'', ''COMMON_SIP_CAMPAIGN_ID''),
        (''KEY'', ''COMMON_SIP_CALL_KEY''),
        (''D1'', ''COMMON_SIP_DATA_1''),
        (''D2'', ''COMMON_SIP_DATA_2''),
        (''D3'', ''COMMON_SIP_DATA_3''),
        (''D4'', ''COMMON_SIP_DATA_4''),
        (''D5'', ''COMMON_SIP_DATA_5''),
        (''PBXIP'', ''COMMON_SIP_PBX_IP_ADDRESS''),
        (''CALLOUT'', ''COMMON_SIP_CALL_ID''),
        (''TS'', ''COMMON_SIP_DATE'')

END
        '
        EXEC(@sql)

SET @process = '5.0 - Drop Create Defined Function GetDateByLangHistory'
SET @sql = '
if exists (select * from sys.objects where object_id = OBJECT_ID(''GetDateByLangHistory''))
    begin
        DROP FUNCTION GetDateByLangHistory
    end
'
EXEC(@sql);

SET @process = '5.1 - Create Defined Function GetDateByLangHistory'
        SET @sql = '
    CREATE FUNCTION [dbo].[GetDateByLangHistory] (@date VARCHAR(MAX), @lang INT)
    RETURNS VARCHAR (MAX)
    AS
    BEGIN
        DECLARE @index INT
        DECLARE @charToFind INT
        SET @index = CHARINDEX(''&'', @date);
        IF(@index <= 0)BEGIN
            RETURN @date;
        END

        DECLARE @iDate VARCHAR(MAX);
        DECLARE @eDate VARCHAR(MAX);

        SET @iDate = SUBSTRING(@date,1,@index-1);
        SET @eDate = SUBSTRING(@date,@index+1,LEN(@date)-@index);

        DECLARE @formatDate DATETIME;
        DECLARE @formatDateToUse SMALLINT = CASE WHEN (@lang = 2 OR @lang = 0) THEN 103 ELSE 101 END;

        DECLARE @iDateFormated VARCHAR(MAX);
        DECLARE @eDateFormated VARCHAR(MAX);
        DECLARE @iHourFormated VARCHAR(MAX);
        DECLARE @eHourFormated VARCHAR(MAX);

        ----Initial Date
        SET @formatDate = CONVERT(DATETIME, @iDate, 120);
        SET @iDateFormated = CONVERT(VARCHAR(MAX), @formatDate, @formatDateToUse);
        SET @iHourFormated = CONVERT(VARCHAR(MAX), @formatDate, 108);

        ----End Date
        SET @formatDate = CONVERT(DATETIME, @eDate, 120);
        SET @eDateFormated = CONVERT(VARCHAR(MAX), @formatDate, @formatDateToUse);
        SET @eHourFormated = CONVERT(VARCHAR(MAX), @formatDate, 108);

        RETURN @iDateFormated + '' '' + @iHourFormated + RIGHT(@iDate, 2) + '' - '' + @eDateFormated + '' '' + @eHourFormated + RIGHT(@eDate, 2)

    END;
        '
        EXEC(@sql)

SET @process = '6.0 - DROP Defined Function GetSipLangHistory'
SET @sql = '
if exists (select * from sys.objects where object_id = OBJECT_ID(''GetSipLangHistory''))
    begin
        DROP FUNCTION GetSipLangHistory
    end
'
EXEC(@sql);
        
SET @process = '6.1 - Create Defined Function GetSipLangHistory'
        SET @sql = '
    CREATE FUNCTION [dbo].[GetSipLangHistory] (@sip VARCHAR(MAX), @lang INT)
    RETURNS VARCHAR (MAX)
    AS
    BEGIN

        DECLARE @stringFormated VARCHAR(MAX) = '''';

        SELECT  @stringFormated = @stringFormated + '' - '' + CASE WHEN B.identifier IS NULL THEN A.Value WHEN @lang = 0 THEN C.TagEs WHEN @lang = 2 THEN C.TagPt ELSE C.TagEn END
        FROM dbo.fn_RIASplitDelimited(@sip, ''_'') AS A 
        LEFT JOIN sipDataIdentifier AS B ON A.Value = B.dataId
        LEFT JOIN ccGalateaIdentifiers AS C ON B.identifier = C.Description
        WHERE Value <> ''''

        SET @stringFormated = RIGHT(@stringFormated, LEN(@stringFormated)-3)

        RETURN @stringFormated

    END;
        '
        EXEC(@sql)

SET @process = '7 - ccsp_GalateaChangeHistory (Option 2) - SP Edited, to get new formats on dates and tags'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
    @option TINYINT,
    @loginLst VARCHAR(max) = NULL,
    @moduleWithOperation varchar(max) = NULL,
    @operationDateIni SMALLDATETIME = NULL,
    @operationDateFin SMALLDATETIME = NULL,
    @top INT = 0
    AS
    SET NOCOUNT ON

    DECLARE @lang TINYINT

    SELECT @lang = valor
    FROM ccsettings
    WHERE setting_id = 27

    IF @option = 1 -- Catalogo de modulos
    BEGIN
        WITH Catalog AS(
        SELECT m.ModuleId as module_id, o.OperationId as operationType, 
        CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS mDescripcion, 
        CASE @lang WHEN 0 THEN OpTagEs WHEN 2 THEN OpTagPt ELSE OpTagEn END AS oDescripcion
        FROM ccGalateaOperations o WITH (INDEX (IX_ccGalateaOperations_Op))
        JOIN ccGalateaModOpRelation r ON o.OperationId = r.OperationId
        JOIN ccGalateaModules m WITH (INDEX (IX_ccGalateaModules_Mod)) ON r.ModuleId = m.ModuleId --WITH (INDEX (IX_ccGalateaModules_Mod))

        UNION

        SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''

        UNION

        SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

        UNION

        SELECT ModuleId as module_id, 0, CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, 
        CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
        FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod))

        UNION

        SELECT ModuleId as module_id, - 1 , CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, '' - ''
        FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod)))

        SELECT module_id,operationType,mDescripcion,oDescripcion 
        FROM Catalog
        ORDER BY mDescripcion, oDescripcion

        RETURN (0)
    END

    IF @option = 2 -- Muestra informacion por filtros
    BEGIN

        declare @sql as nvarchar(max)
        DECLARE @table TABLE(id int,value varchar(max))
        declare @id int
        declare @moduleId varchar(max)
        declare @operationLst varchar(max)
        declare @query varchar(max) = '' and (''
        declare @value varchar(max)
        declare @first int = 1
        declare @pos int

        insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
        while exists(select * from @table)
        begin
            select top 1 @id = id, @value = value from @table
            set @pos = charindex('':'', @value)
            if(@pos <> 0)
            begin
                set @moduleId = substring(@value, 1, @pos-1)
                set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
                if(@first = 1)
                begin
                    set @query = @query + ''l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
                    set @first = 0
                end
                else
                begin
                    set @query = @query + '' or l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
                end
            end

            delete @table where id = @id
        end
        set @query = @query + '')''


        SET ROWCOUNT @top

        set @sql =
        ''DECLARE @tableLogin TABLE(id int,value varchar(255))
        insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

        SELECT L.LogId as log_id, L.Area as areaName, L.ActivityDate as operationDate,
        CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN O.OpTagEs WHEN 2 THEN O.OpTagPt ELSE O.OpTagEn END operationType,
        L.LOGIN,
        CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN M.MTagEs WHEN 2 THEN M.MTagPt ELSE M.MTagEn END module_id,
        CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
        CASE WHEN i.description IS NULL THEN L.Identifier ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN i.TagEs WHEN 2 THEN i.TagPt ELSE i.TagEn END END +
        CASE WHEN L.Identifier<>'''''''' AND L.Value<>'''''''' THEN '''': '''' ELSE '''''''' END +

        CASE WHEN V.description IS NULL 
            THEN 
                CASE 
                    WHEN L.Identifier<>'''''''' AND (L.Identifier LIKE ''''COMMON_DELETE_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_ADD_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_DATE%'''')
                        THEN dbo.GetDateByLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
                    ''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''OUT_SIP_IDENTIFIER'''' THEN dbo.GetSipLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
            ''ELSE L.value END
            ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.TagEs WHEN 2 THEN v.TagPt ELSE v.TagEn END END AS value

        FROM ccGalateaActivityLog L
        JOIN ccGalateaModules M WITH (INDEX (IX_ccGalateaModules_Mod)) ON L.ModuleId = M.ModuleId
        JOIN ccGalateaOperations O WITH (INDEX (IX_ccGalateaOperations_Op)) ON L.OperationId = O.OperationId
        LEFT JOIN targetRecord t ON t.targetT = L.target
        LEFT JOIN ccGalateaIdentifiers i ON i.Description = L.Identifier
        LEFT JOIN ccGalateaIdentifiers v ON v.Description = L.Value
        LEFT JOIN ccUsers CU ON CU.Login = L.login
        WHERE 1=1 
        AND
        CU.TipoUser_id = 2''
        +
        case isnull(@loginLst, '''') when '''' then '''' else
        '' AND L.LOGIN in (select value from @tableLogin) ''
        END
        +
        case isnull(@moduleWithOperation, '''') when '''' then '''' else
        @query
        end
        + case ISNULL(@operationDateIni, '''') when '''' then '''' else
        ''AND L.ActivityDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.ActivityDate END ''
        + '' AND L.ActivityDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.ActivityDate END''
        end
        +
        '' ORDER BY L.ActivityDate DESC''
        execute sp_executesql @sql
        --print @sql
    END


    SET NOCOUNT OFF
        '
        EXEC(@sql)

SET @process = '8.0 - DROP SP InsertLogAdminGalatea'
SET @sql = '
    if exists (select * from sys.procedures where name = ''InsertLogAdminGalatea'')
    begin
        DROP PROCEDURE InsertLogAdminGalatea;
    end
'
EXEC(@sql);

SET @process = '8 - InsertLogAdminGalatea - New SP, created to get the difference of one record table after after be updated'
        SET @sql = '
CREATE procedure [dbo].[InsertLogAdminGalatea]
    @action int 
    ,@tableName VARCHAR(255)
    ,@columnNameId VARCHAR(255)
    ,@valueId VARCHAR(255)
    ,@userId int
    ,@tableTemp varchar(255)=null
as
SET NOCOUNT ON;

    -- Insert statements for procedure here
    declare @sql varchar(max),@sql2 varchar(max)
    DECLARE @tableNameTmp VARCHAR(255) = ''##''+@tableName+''_''+convert(varchar(10),@userId)
if @action =1 begin --Antes del cambio

 set @sql=''
IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp+''
SELECT * INTO ''+@tableNameTmp+'' FROM ''+@tableName+'' WHERE ''+@columnNameId+'' = ''+@valueId
print(@sql)
exec(@sql)

end
else if @action=2 begin
    DECLARE @object_name SYSNAME, @object_id INT;
    DECLARE @columns nVARCHAR(max) = '''',@columns2 nVARCHAR(max) = '''',@columns3 nVARCHAR(max) = ''''
    , @pivot NVARCHAR(max) = ''''
    ,@maxLength int=4000
SELECT @object_name = ''['' + s.name + ''].['' + o.name + '']'', @object_id = o.object_id
FROM sys.objects AS o WITH (NOWAIT)
INNER JOIN sys.schemas AS s WITH (NOWAIT) ON o.schema_id = s.schema_id
WHERE o.name = @tableName
    AND o.type = ''U''
    AND o.is_ms_shipped = 0;

SELECT --case when A.AreaName=B.AreaName then 1 else 0 end AreaName
@columns3 =@columns3+  case when len( @columns2)>@maxLength and len( @columns2)>=@maxLength then '',case when A.['' + c.name + '']=B.['' + c.name + '']then''''''''else convert(varchar(300),A.['' + c.name + '']) end '' 
    + c.name else '''' end
    ,@columns2 =@columns2+  case when len( @columns)>=@maxLength and len( @columns2)<=@maxLength  then '',case when A.['' + c.name + '']=B.['' + c.name + '']then''''''''else convert(varchar(300),A.['' + c.name + '']) end '' 
    + c.name else '''' end
    ,@columns =@columns+  case when len( @columns)<=@maxLength then '',case when A.['' + c.name + '']=B.['' + c.name + '']then''''''''else convert(varchar(300),A.['' + c.name + '']) end '' 
    + c.name else '''' end

    

    ,@pivot=case when len( @pivot)<=@maxLength then @pivot+'',['' + c.name + '']'' else '''' end

FROM sys.columns AS c WITH (NOWAIT)
INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
    AND c.column_id = cc.column_id
LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
    AND c.object_id = dc.parent_object_id
    AND c.column_id = dc.parent_column_id
LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
    AND c.object_id = ic.object_id
    AND c.column_id = ic.column_id
WHERE c.object_id = @object_id
    AND c.name <> ''rowguid''
ORDER BY c.column_id


SET @columns =  SUBSTRING(@columns, 2, len(@columns))
SET @pivot = SUBSTRING(@pivot, 2, len(@pivot))


declare @insertTable nvarchar(max)

set @insertTable='' select A.columnInfo,A.dataInfo,isnull(B.Identifiers,'''''''') as identifierInfo from rowInfo A
left join relationTableColumnIdentifiers B on A.columnInfo=B.colunName and B.tableName=''''''+@tableName+''''''''

if @tableTemp is not null and @tableTemp<>'''' begin
    set @insertTable= ''insert into ''+@tableTemp +'' ''+   @insertTable
end


PRINT (
'';WITH result AS (SELECT '' + @columns  + '' 
'')
print(
@columns2+ '' 
'')
print( @columns3+ '' FROM '' + @tableName + '' A
inner join '' + @tableNameTmp + '' B on A.['' + @columnNameId + '']=B.['' + 
    @columnNameId + '']
),
rowInfo as (
    SELECT columnInfo,dataInfo
FROM
(
  SELECT ''+@pivot+'' FROM result
) p
UNPIVOT
(
  dataInfo  for columnInfo IN (''+@pivot+'')
) AS upvt
where dataInfo<>''''''''
)
''+@insertTable
);

exec(
'';WITH result AS (
SELECT '' + @columns  + @columns2+@columns3+ '' FROM '' + @tableName + '' A
inner join '' + @tableNameTmp + '' B on A.['' + @columnNameId + '']=B.['' + 
    @columnNameId + '']
),
rowInfo as (
    SELECT columnInfo,dataInfo
FROM
(
  SELECT ''+@pivot+'' FROM result
) p
UNPIVOT
(
  dataInfo  for columnInfo IN (''+@pivot+'')
) AS upvt
where dataInfo<>''''''''
)''
+@insertTable
)


end
else if @action =3 begin

 set @sql=''
IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp  

--print(@sql)
exec(@sql)
end
        '
        EXEC(@sql)


SET @process = '9 - ccsp_GalateaAreas (option 3, 4 y 5)- SP Edited, edited to add records to Activity Log, (Crear, Editar, Eliminar Area)'
        SET @sql = '
ALTER procedure [dbo].[ccsp_GalateaAreas] 
    @option int = 2,
    @IDArea smallint = 0,
    @Descripcion varchar(40) = NULL,
    @maxMails smallint = 3,
    @maxChats smallint = 3,
    @maxTweets smallint = 3,
    @defCampaing smallint = 0,
    @movesfromArea bit = 0,
    @userId int = NULL,
    @groupAreas varchar (MAX) = NULL
AS

SET NOCOUNT ON;
    
    declare @opt int = @option -1
    
    DECLARE @userLogin as varchar(40);
    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

    if @option = 1 --Superuser info
    begin
        create table #campsIds(
            id int,
            cadena varchar(max)
        )
            
        declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
        set @idPivots =''''
        set @idConcat=''''
            
        select @idPivots=@idPivots+Id+'','',
            @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
            ''
            from (
            select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
            )x
            
        set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
        set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
        set @sql=''
            select IDArea,''+@idConcat+'' from 
            (   select IDArea, cam_id from ccCamps) as T
            PIVOT (
            max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

        insert into #campsIds
        exec(@sql)
            
        select a.IDArea Id, 
            a.AreaName Name, 
            a.StatusArea Status, 
            a.maxMails Mails, 
            a.maxChats Chats, 
            a.maxTweets Tweets, 
            a.CreateDate as CreateDate,         
            ISNULL(b.cadena, 0) as CampaignIds  
        from ccRIACat_Areas a --Falta el datetime 
        left join #campsIds b on a.IDArea = b.id

        drop table #campsIds
    end
    if @option = 2 -- Select de las areas
    begin
        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        Create table #Areas(
            IDArea smallint,
            AreaName varchar(MAX),
            maxChats tinyint ,
            maxMails tinyint ,
            users int,
            admins int,
            camps int,
            acds int,
            maxTweets tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing
        select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
        from #Areas a
        inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea
    end
    if @option = 3 -- Insert new area
    begin
    IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
        Create table #InsertAreas(
            result int,
            idAreas decimal
        )
        insert into #InsertAreas
        EXEC ccsp_RIA_ABCAreas 
            @option = @opt,
            @IDArea=@IDArea,
            @Descripcion=@Descripcion,
            @maxMails=@maxMails,
            @maxChats=@maxChats,
            @maxTweets=@maxTweets,
            @defCampaing=@defCampaing
        if (select result from #InsertAreas) = 1
            begin

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                if(@movesfromArea = 1) begin
                    Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                end
            end
        Select * from #InsertAreas
    end
    if @option = 4 -- Delete Areas
    begin
        IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
        SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
        if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
          or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
        BEGIN
            Select -1 as result
        END
        ELSE
        BEGIN
            declare @DWorkGroups as varchar(500)
            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select user_id,cam_id,prioridad,skill,rel_id,IDWG
            from ccCampsAgente
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
            select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
            from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
            select user_id,cam_id,tipo,IDWG,monitored
            from ccSupervisorCam
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
            where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

            Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

            Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

            select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
            Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

            if (select valor from ccSettings where setting_id=95)=1
            begin
            Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
            Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            end

            Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

            --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
            FROM ccRIACat_Areas 
            WHERE IDArea in (Select IDArea from #AreasDelete);

            select 1 as result
        END
    end
    if @option = 5 -- update Areas
    begin
        if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
            begin
                select -1 as result
                return
            end
        else
            begin

                --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                DECLARE @PrevDescription AS VARCHAR(50);
                DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                SELECT @PrevDescription = AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea = @IDArea;

                EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                DECLARE @AreasTable TABLE 
                (
                    columnInfo VARCHAR(255),
                    dataInfo VARCHAR(255),
                    identifierInfo VARCHAR(255)
                )

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0) where IDArea=@IDArea

                INSERT INTO @AreasTable EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId;

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END,
                    getDate(), 
                    @userLogin, 
                    18, 
                    3, 
                    AT.identifierInfo,
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                            WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                CASE 
                                    WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                    ELSE ''T&COMMON_NONE'' END
                            ELSE AT.dataInfo END
                    ELSE '''' END, 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END
                FROM @AreasTable AS AT;

                EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

            end
        if @maxChats is not null
            begin
                Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
            end
        if @movesfromArea = 1
        Begin
            Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
        End
        select 1 as result
    end
SET NOCOUNT ON;
        '
        EXEC(@sql)

        SET @process = '10 - ccsp_GalateaAdminWorkgroups (Option 5 y 6) - SP Edited, edited to add records to Activity Log, (Crear, Eliminar Grupo de trabajo)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
    @Option AS SMALLINT,
    @AdminId AS INT = 0,
    @WorkgroupId AS INT = 0,
    @idArea AS INT = NULL,
    @Descripcion AS varchar(40) = null,
    @groupList as varchar (MAX) = NULL

AS
declare @users as int
declare @camps as int
declare @sql as varchar(max)

BEGIN

    DECLARE @userLogin AS VARCHAR(40) = '''';
    DECLARE @areaName AS VARCHAR(40) = '''';

    IF @Option = 1
    BEGIN 
        if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
        BEGIN
            select  CAST(wg.IDWG as int)  as Id, wg.WGName Name, wg.StatusWorkGroup Status
            from ccRIACat_WorkGroup wg
            where StatusWorkGroup = 1
        END

        ELSE
        BEGIN
            SELECT @AdminId = ISNULL(@AdminId, 0)           
        
            SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
            JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
            WHERE User_id = @AdminId
        END     
                    
    END
    IF @Option = 2
    BEGIN 
        SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)           
        
        SELECT CAST(wg.IDWG AS INT) AS Id,
                WGName Name,
                StatusWorkGroup Status  
        FROM 
        ccRIACat_WorkGroup wg 
        WHERE IDWG = @WorkgroupId
                    
    END

    IF @Option = 3 --Lista de wg 
    BEGIN 
    
        SELECT cast(IDWG as int) Id, WGName as Name
        FROM ccRIACat_WorkGroup
        WHERE StatusWorkGroup =1
                    
    END

    IF @Option = 4 --Lista de wg por area
    BEGIN 
        SELECT @idArea = ISNULL(@idArea, 0) 

        SELECT CAST(IDWG as int) IDWG 
        FROM 
        ccRIAAreaWorkGroup
        WHERE IDArea = @idArea
                    
    END

    IF @Option = 5 --Delete WG
    BEGIN
        --revisar tablas con relacion de grupos de trabajo
        IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
        SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')

        SELECT @camps=count(IdCampEsp) 
        FROM ccRIACampEspWG 
        where IDWG in  (select IDwg from #WGDelete)

        SELECT @users=count(User_id) 
        FROM ccRIAWorkGroupUsers 
        where IDWG in (select IDwg from #WGDelete)

        if @users>0 or @camps >0 
        begin
            select -1
        end
        else
        begin
            Delete from ccRIAAreaWorkGroup where IDWG in (select IDwg from #WGDelete)
            Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG in (select IDwg from #WGDelete)

            SET @userLogin = (SELECT [Login] from ccUsers WHERE User_id = @AdminId);
            SET @areaName = (SELECT [AreaName] from ccRIACat_Areas WHERE IDArea = @IDArea);

            IF (@userLogin <> '''' AND @areaName <> '''')
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                SELECT @areaName, getDate(), @userLogin, 21, 3, '''', '''', WGName
                FROM ccRIACat_WorkGroup 
                WHERE IDWG in (Select IDwg from #WGDelete);

            select 1
        end
        

    END

    if @option = 6 -- Verifica si existe el grupo
         begin
            select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
             then 1 else 0 end
         
            if isnull(@IDArea,0)=0
             begin
                select @WorkgroupId
                return(0)
             end

            if @WorkgroupId=1
             begin
             set @WorkgroupId = -1
                select @WorkgroupId
                return(0)
             end

            insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)

            if @@rowcount = 1
                select @WorkgroupId = scope_identity()

            SET @userLogin = (SELECT [Login] from ccUsers WHERE User_id = @AdminId);
            SET @areaName = (SELECT [AreaName] from ccRIACat_Areas WHERE IDArea = @IDArea);
            IF (@userLogin <> '''' AND @areaName <> '''')
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 20, 3, '''', '''', @Descripcion);

            insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
            select @WorkgroupId
            return(0)
         end

END
        '
        EXEC(@sql)


        SET @process = '11 - ccsp_GalateaCreateUser - SP Edited, edited to add records to Activity Log, (Crear Agente / Administrador)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaCreateUser]
                    @UserId int,
                    @Login varchar(40),
                    @Nombres varchar(45),
                    @LastName varchar(45),
                    @NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
                    @Password varchar(200),
                    @Sexo bit,
                    @canChangeStatus bit,
                    @AreaId int,
                    @UserType tinyint,
                    @AdminId int
                    as

                    Declare @ApellidoMaterno varchar(45)
                    Declare @ApellidoPaterno varchar(45)

                    --Obtiene el idioma de de Centerware
                    Declare @lenguageXion varchar
                    select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

                    --se acondiciona los apellidos con el nombre opcional dependiendo del idioma
                        if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
                        begin
                            set @ApellidoPaterno = @LastName
                            set @ApellidoMaterno = @NombreOpcionalExtra
                        end
                        else-- es idioma ingles
                        begin
                            set @ApellidoPaterno = @NombreOpcionalExtra 
                            set @ApellidoMaterno = @LastName
                        end

                    -- validaciones 
                        if exists(select Login from ccUsers where Login=@Login)
                        begin
                        select -1 as ResponseCode--,''Login en Uso''
                        return(0)
                        end

                        if exists(select Login from ccUsers_Consulta where Login = @Login)
                        begin
                        select -4 as ResponseCode -- ''Login en Uso aunque el usuario ya se halla borrado de la base de datos'' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
                        return(0)
                        end

                        if exists(select Nombres from ccUsers where Nombres=@Nombres
                        and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
                        begin
                        select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
                        return(0)
                        end


                    --insert
                    IF( select isnull(max(user_id),0) from ccusers) > 32700
                    BEGIN
                        set @UserId = null
                        SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
                        FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
                        LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
                        INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
                        FROM ccusers) AS w ON w.recID = d.recID

                        if @UserId is null
                        begin
                        select -3 as ResponseCode --Error_when_inserting_user
                        return(0)
                        end

                        set identity_insert ccusers on
                        insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id, Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
                        select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
                        set identity_insert ccusers off

                        delete ccMenuUser where id_User = @UserId
                        delete ccRIAUserRole where user_id = @UserId

                        exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

                        --Insert Agent into ccRIAAgentsPermissions
                        IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
                        BEGIN
                        IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
                        BEGIN 
                            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
                            VALUES (@UserId, 0, 0, 1)
                        END
                        END

                    END
                    ELSE
                    BEGIN
                        insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
                        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
                        select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
                        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

                        if @@rowcount=1
                        select @UserId=scope_identity()
                        else
                        begin
                        select -2--insert Error
                        return(0)
                        end

                        --INSERT INTO ACTIVITY LOG, CREATE AGENT
                        DECLARE @areaName AS VARCHAR(40);
                        DECLARE @userLogin AS VARCHAR(40);
                        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId);

                        IF(@AreaId <> 0) BEGIN
                            SET @areaName = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId);
                        END

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                        VALUES (CASE WHEN @AreaID = 0 THEN NULL ELSE @areaName END, getDate(), @userLogin, CASE WHEN @UserType = 1 THEN 22 ELSE 29 END, 3, '''', '''', @Login);

                    END
                        insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
                        insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
                        insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
                        --Menu para roles RepotsRia
                        exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

                        --Insert Agent into ccRIAAgentsPermissions
                        IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
                        BEGIN
                        IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
                        BEGIN 
                            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
                            VALUES (@UserId, 0, 0, 1)
                        END 
                        END
                    select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario
        '
        EXEC(@sql)


        SET @process = '12 - ccsp_GalateaManageWG (Option 1, 2, 3, 4 y 5 ) - SP Edited, edited to add records to Activity Log, (Asignar/Desasignar Agente/Administrador/Campaña, Cambiar Agente/Administrador de Area)'
        SET @sql = '
ALTER PROCedure [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) ='''',
@idNewArea int = 0,
@LoginId int = 0,
@AreaId int = 0
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
    select 0 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
    union
    select 1 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
    ) as Camps ) as CampsInOut

select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
    value As user_id
    into #UsersList
    FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

IF(@option = 1 OR @option = 2) BEGIN

    DECLARE @areaName VARCHAr(50);
    DECLARE @userLogin VARCHAR(40);
    DECLARE @workGroupName VARCHAR(40);
    DECLARE @userToAffect VARCHAR(40);
    DECLARE @campName VARCHAR(40);

END

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user

        if @Type in(1, 2, 6)
        begin

            if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
            begin
            

                If @Type = 1
                 begin

                        If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from ccSettings where setting_id = 63)
                         begin
                            insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)

                            --INSERT LOG RECORD (ASSIGN AGENT)
                            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 23, 3, '''', @userToAffect, @workGroupName);

                            select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                            --insert skill media
                            exec ccsp_Skills @action= 5,@userId=@user

                            insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
                            select @user, idCampEsp, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and
                             idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)

                            insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
                            select @user, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and
                            idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

                            if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                                insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                            end
                        end
                 end
                 else if @Type in(2, 6)
                 begin
                    -- -Supervisor  @Type in (2,6)
                    insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)

                    --INSERT LOG RECORD (ASSIGN ADMIN)
                    SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                    SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 30, 3, '''', @userToAffect, @workGroupName);

                    select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                    if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                        insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                    end

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 0, @IDWG
                    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
                    and tipo = 0
                    and IDWG <> @IDWG
                    and monitored = 0

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 1, @IDWG
                    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
                    and tipo = 1
                    and IDWG <> @IDWG
                    and monitored = 0
                end
                
            end
        end
        set @id = @id+1
    end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user
        
        if @Type = 1 --delete skill media
        exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG
        
        if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
        begin
        
            Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
        

            if @Type = 1 -- Agente
             begin

                --INSERT LOG RECORD (UNASSIGN AGENT)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 24, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

                delete from cccampsagente where user_id=@user and IDWG=@IDWG
                delete from ccInboundagentes where user_id=@user and IDWG=@IDWG

                --update preview permission
                update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id = @user group by user_id)c on us.User_id=c.user_id
                where us.user_id = @user
                --select @Type
             end
             else if @Type in(2, 6) -- Supervisor
             begin

                --INSERT LOG RECORD (UNASSIGN ADMIN)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 31, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
                --select @Type
            end
        end
        set @id = @id+1
    end
end
if @option in (1,2)
begin
    if LEN(@Assigned) > 0
        select SUBSTRING(@Assigned,0,Len(@Assigned))
    else
        select @Assigned

    return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup  
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
    begin
         select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
         

         if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) < (select valor from ccSettings where setting_id=180) -- limit
             begin

                if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) < (select valor from ccSettings where setting_id=64) -- limit
                    begin

                        if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
                        begin

                            insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
                            if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
                                insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
                            end   

                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
                            IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
                            ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            VALUES (
                                (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
                                getDate(), 
                                @userLogin, 
                                36, 
                                3, 
                                '''', 
                                @campName,
                                (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
                            );

                            exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
                            if @Type in (0, 1) -- ACDGroup
                            begin

                                if @IDWG is not null or @IDWG = 0
                                begin
                                    if @Type=0 --ACDGroup
                                    begin
                                        select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
                                        SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                            join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
                                        and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 0, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
             
                                        --return(0)
                                    end

                                    else if @Type = 1 -- Camp
                                    begin
                                        select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
                                        SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                        join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
                                            and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
            
                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 1, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
                                    end
                            end
                        end
                    end
                end
            end
        set @id = @id + 1
   end
end

if @option = 3
begin
    
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
        select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
    else
        select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

    return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

        select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id

        SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 1

        SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 2

        --Delete Agent from WorkGroup
           set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
           exec(@sql)

         --Delete Supervisor from WorkGroup

         set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
           exec(@sql)

        --Delete WokGroup from ACD or Camp 

        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
        IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
        ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
            getDate(), 
            @userLogin, 
            59, 
            3, 
            '''', 
            @campName,
            (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
        );


         set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
         exec(@sql)
        set @id = @id + 1
    
    end

    select 1
    return 0
end

if @option = 5  --Change Admin Administrator.
begin
declare @user_id int
select @user_id = value FROM fn_RIASplitDelimited(@usersList, '','')
select @Type = TipoUser_id from ccUsers where User_id = @user_id

        if @Type = 1 -- Agente
        begin

            if(select count(user_id) from ccCampsAgente where user_id = @user_id) >0 or 
            (select count(user_id) from ccInboundAgentes where user_id = @user_id) >0 or
            (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
            begin
                select -1
                return 0
            end
            else

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                VALUES (@areaName, getDate(), @userLogin, 27, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

                update ccUsers set IDArea = @idNewArea where user_id = @user_id
        end

        
    if @Type in (2, 6) -- Supervisor
    begin

        if(select count(user_id) from ccSupervisorCam where user_id = @user_id) > 0 or
        (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
        begin
            select -1
            return 0
        end
        else

            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            VALUES (@areaName, getDate(), @userLogin, 34, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

            update ccUsers set IDArea = @idNewArea where user_id = @user_id
    end

    update ccPosicion set user_id = 0 where user_id = @user_id

    select 1

end

set nocount off
        '
        EXEC(@sql)


        SET @process = '13 - ccsp_GalateaUpdateUser - SP Edited, edited to add records to Activity Log, (Editar Agente/Administrador)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Sexo bit,
@canChangeStatus bit,
@AdminId int,
@AreaId int
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @userIdOnDb int
Declare @LoginOnDb varchar(40)
--Obtiene el idioma de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
    if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
        begin
            set @ApellidoPaterno = @LastName
            set @ApellidoMaterno = @NombreOpcionalExtra
        end
    else-- es idioma ingles
        begin
            set @ApellidoPaterno = @NombreOpcionalExtra 
            set @ApellidoMaterno = @LastName
        end

-- validaciones 
    if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
        begin
        select -5 as ResponseCode--,''el usuario no existe''
        return(0)
        end

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin

        select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

        select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

      if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
        begin
            select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
            return(0)
        end
    end

--update and insert into activity log a record for each modified property

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

    Update ccUsers set 
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,
    ApellidoMaterno=@ApellidoMaterno,
    Sexo=@Sexo,
    canChangeStatus=@canChangeStatus
    where User_id=@UserId

    DECLARE @CCUsersTable TABLE 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    INSERT INTO @CCUsersTable EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
        CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
        3, 
        CUT.identifierInfo,
        CASE WHEN CUT.identifierInfo IS NOT NULL THEN
            CASE 
                WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
                ELSE CUT.dataInfo END
        ELSE '''' END, 
        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
    FROM @CCUsersTable AS CUT;

    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
        '
        EXEC(@sql)


        SET @process = '14 - ccsp_GalateaUpdatePassword - SP Edited, edited to add records to Activity Log, (Cambiar contraseña Agente/Administrador)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdatePassword]
        @UserId smallint,
        @Login varchar(40),
        @Password varchar(33),
        @AdminId int,
        @AreaId int
        as
    
        -- validaciones 
            if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
                begin
                    select -5 as ResponseCode--el usuario no existe
                    return(0)
                end

            if  @Password <> '''' 
                begin 
                    declare @date datetime = GETDATE()
                    declare @setting207 int = (select valor from ccSettings where setting_id=207)

                    if (@setting207 = 1 and exists(select Password from ccPasswordHistory where Password=@Password and User_id=@UserId))
                     begin
                        select -7 as ResponseCode -- La contraseña ya existe
                     end
                    else
                     begin
                        Update ccUsers set Password=@Password, LastPasswordChange = @date, isBlocked=0, LoginAttempts=0 where User_id=@UserId   and Login=@Login

                        --BEGIN Insert record to activity log - Change Password
                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
                            getDate(), 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
                            CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId AND Login = @Login) = 1 THEN 26 ELSE 33 END, 
                            3, 
                            '''',
                            '''', 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
                        --END Insert record to activity log - Change Password
                
                        if @setting207 = 1
                         begin
                            insert into ccPasswordHistory(User_id, Password, PasswdDate)
                            values (@UserId, @Password, @date)
                         end

                        select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
                     end
                end
            else
                begin 
                    select -6 as ResponseCode -- la nueva contraseña es vacia
                end
        '
        EXEC(@sql)


        SET @process = '15 - ccsp_RIAManageAreas - SP Edited, edited to add records to Activity Log, (Eliminar Agente/administrador)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null,
@AdminId smallint = 0
as
set nocount on

if @option = 1 -- Insert User Area
    begin
    if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
        begin
        Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
        return(0)
        end 
                     
    select 1
    return(0)
    end

if @option = 3 -- Insert camp area
    begin
    if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
        begin
        Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
        where cam_id = @InsertCamId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 4 begin-- Delete camp area
    

    --Si existe una campa? relacionada con el grupo
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
        select -4
        return(0)    
    end

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
                 
    delete from ccCampsAgente where cam_id = @DeleteCamId   

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1    

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1  
    delete from ccoWorkingTable where cam_id = @DeleteCamId
    
    Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
    return(0)
    end

if @option = 5 -- Insert ACDGroup area
    begin
    if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
        begin
        Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 6 -- Delete ACDGroup area
    begin
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
    delete ccInboundDnis where Inbound_id = @DeleteACDGroupId

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
    select 1
    return(0)
    end

if @option in (2, 9, 10, 11)
    begin
        declare @Type tinyint
    select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
                    
    if @option in (2, 10, 11) -- Delete User area
        begin
        if @Type = 1 -- Agente
            begin

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

            delete from ccCampsAgente where user_id = @DeleteUserId
            delete from ccInboundAgentes where user_id = @DeleteUserId

            if @option = 11
                begin
                    select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

                    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                                    
                    select * from #WorkGroupUsers
                    drop table #WorkGroupUsers
                                    
                    return(0)
                end
            end

        else if @Type in (2, 6) -- Supervisor
        begin
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            delete from ccSupervisorCam where user_id = @DeleteUserId
        end

        delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                        
        if @option=2
            begin
            update ccPosicion set user_id = 0 where user_id = @DeleteUserId
            update ccUsers set IDArea = null where user_id = @DeleteUserId  
            end
        return(0)
    end

    declare @UserWG varchar(100)
    -- @option = 9 -- Delete User area and get his workgroups

    select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

    if @Type = 1 -- Agente
        begin
        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccCampsAgente where user_id = @DeleteUserId
        delete from ccInboundAgentes where user_id = @DeleteUserId
        end

    if @Type in (2, 6) -- Supervisor
        begin
        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccSupervisorCam where user_id = @DeleteUserId
        delete from ccMenuUser where id_User = @DeleteUserId
        end

    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
    update ccPosicion set user_id = 0 where user_id = @DeleteUserId
                    
    if @option <> 11 BEGIN

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas AS CCRA, ccUsers AS CCU WHERE CCU.User_id = @DeleteUserId AND CCRA.IDArea = CCU.IDArea),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId),
            CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @DeleteUserId) = 1 THEN 28 ELSE 35 END,
            3,
            '''', 
            '''',
            (SELECT [Login] FROM ccUsers WHERE User_id = @DeleteUserId)
        );

        update ccUsers set IDArea = null where user_id = @DeleteUserId
    END
                    
    select @UserWG, @Type
    return(0)
    end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 begin-- Delete camp area
    
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
    
        ---Borra las calificacion con reprogramacion
        delete ccCalifCamp from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
        where A.cam_id=@DeleteCamId
        ---Borra las subcalificacion con reprogramacion
        delete rel from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id 
        inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
        inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        where A.cam_id=@DeleteCamId and sb.canReprogram=1
    
        update ccInbound set cam_id = null where cam_id=@DeleteCamId                
         
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

    delete from ccCampsAgente where cam_id = @DeleteCamId
    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1
    
    delete from ccoWorkingTable where cam_id = @DeleteCamId  

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    select @AreaDescripcion = area.AreaName
    from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
        with(nolock) on camp.IDArea = area.IDArea
    where camp.cam_id = @DeleteCamId
    Update ccCamps set IDArea = null where cam_id = @DeleteCamId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    return(0)
    end

if @option = 8 --Delete ACDGroup area
    begin
    if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
    begin
        update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
    delete ccInboundDnis where Inbound_id = @DeleteACDGroupId

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    select @AreaDescripcion = area.AreaName
    from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
        with(nolock) on ACD.IDArea = area.IDArea
    where ACD.Inbound_id = @DeleteACDGroupId
    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    
    if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        DECLARE @TwitterResult table(--Se declaro por que el SP ccsp_MailAdminAccount regresa una consulta.  
        result int,  
        operation varchar(30));
        insert @TwitterResult
        EXEC [dbo].[ccsp_MailAdminAccount] @action = 22,@meanContactTypeId = 2, @inboundId = @DeleteACDGroupId--se ejecutara el SP para desasociar la cuenta de mail
    end
    if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId = @DeleteACDGroupId and meanContactTypeId=1
    end
    update ccinbound set chatDomain = '''' where inbound_id = @DeleteACDGroupId--para desasociar el dominio del chat
    return(0)
    end

return(0)
set nocount off
        '
        EXEC(@sql)

        SET @process = '16 - ccsp_RIA_ABCACDGroups (Option 2) - SP Edited, edited to add records to Activity Log, (Crear camapaña de entrada (Llamada/WhatsApp))'
        SET @sql = '
ALTER procedure [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint,
@Prefijo varchar(40) = null,
@MediaType int
as
set nocount on
declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
     select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
    isnull(areas.areaname,'''') as areaname
     from ccinbound as acd with(nolock)
     left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
     return(0)
 end

if @option = 1 -- select acd
 begin
     select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id,
     prefijo as Prefijo
     from ccinbound a1 
      inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
      inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
     where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
     order by descripcion
     return(0)
 end

if @option = 2 -- insert
 begin
 
    if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
     begin
            select -1--, ''nombre en uso''
            
            return(0)
     end
    
    if @idarea = 0
    set @idarea = null


    declare @pref int
    select  @pref = valor from ccSettings where setting_id = 201
    if (@pref = 0)
        set @Prefijo = ''''
    
    DECLARE @tempDesc VARCHAR(40);
    SET @tempDesc = CASE WHEN @MediaType = 5 THEN @descripcion ELSE @descripcion+''Tmp'' END;

    insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd,prefijo)
    select @tempDesc, 1, @idarea,case when exists(select calif_id from cctipocalif) then 1 else 0 end
     , @Prefijo
    
    if @@rowcount = 1
        select @new_inbound_id = inbound_id from ccinbound where descripcion = @tempDesc and status = 1

    else
     begin
        select -2 -- Error al insertar
        return(0)
     end

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @new_inbound_id, @userId= @userid

     UPDATE ccInbound SET 
        descripcion = @descripcion,
        ShowCalifWnd = case when exists(select calif_id from cctipocalif) then 1 else 0 end
    WHERE Inbound_id = @new_inbound_id

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';    
    
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE WHEN @MediaType = 5 THEN 40 ELSE 60 END, 
        3, 
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @MediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
             WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @new_inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

    if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
     begin
        insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
        select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
     end

    if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
     begin
        insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
        select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
     end

    if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
     insert into ccriagraphics (frame,type_id) values (@frame,1)
    
     select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
     
     insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
     select @new_inbound_id
     return(0) 
 end

if @option = 3 -- update
 begin
     if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
        insert into ccriagraphics (frame, type_id) values (@frame, 1)

     select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
     update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
     update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
     return(0)
 end

if @option = 4 -- delete
 begin
     delete cccalifcamp where cam_id = @inbound_id and tipo = 0
     delete ccinboundhorarios where inbound_id = @inbound_id
     delete ccriainboundgraph where inbound_id = @inbound_id
     delete ccInboundMsgs where inbound_id = @inbound_id
     delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
     delete ccinbound where inbound_id = @inbound_id
     return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
    if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
     (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
        not exists (select cam_id from ccCamps where cam_id=@descripcion))
     begin
        select -3 -- Campaña o ACD invalido
        return(0)
     end
    
    if @descripcion=0 begin

        set @descripcion = null
        --quitamos calificaciones relacionadas a la campaña
        DELETE c FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
        Where c.cam_id=@inbound_id and ci.CanReprogram =1
        --quitamos subcalificaciones relacionadas a la calificacion
        DELETE rel FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
        inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
        left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        Where c.cam_id=@inbound_id and sb.canReprogram=1
                
    end
    
    update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
        
    if @@rowcount=0
        select -4 -- Error al actualizar

    return(0)
 end
set nocount off

        
        '
        EXEC(@sql)


        SET @process = '17 - ccsp_RIAUpdateEspecConfig - SP Edited, edited to add records to Activity Log, (Crear camapaña de entrada (Llamada/WhatsApp))'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] @inbound_id              SMALLINT, 
                                                  @descripcion             VARCHAR(50)  = NULL, 
                                                  @Status                  TINYINT      = NULL, 
                                                  @tNotas                  INT          = NULL, 
                                                  @tMaxWaitCall            INT          = NULL, 
                                                  @nMaxQue                 INT          = NULL, 
                                                  @tel_maxwait             VARCHAR(15)  = NULL, 
                                                  @tel_MaxQueue            VARCHAR(15)  = NULL, 
                                                  @tel_outservice          VARCHAR(15)  = NULL, 
                                                  @tel_noct                VARCHAR(15)  = NULL, 
                                                  @ShowCalifWnd            BIT          = NULL, 
                                                  @StartTimerOnHangUp      BIT          = NULL, 
                                                  @editableCallKey         BIT          = NULL, 
                                                  @queuePosition           BIT          = NULL, 
                                                  @tMaxQueueCallBack       SMALLINT     = NULL, 
                                                  @stopRecording           BIT          = NULL, 
                                                  @dialPrefixOverflow      VARCHAR(10)  = NULL, 
                                                  @OpriorityT              SMALLINT     = NULL, 
                                                  @callerIdDesc            VARCHAR(15)  = NULL, 
                                                  @chat                    TINYINT      = NULL, 
                                                  @inactiveChatTime        SMALLINT     = NULL, 
                                                  @maxChats                TINYINT      = NULL, 
                                                  @chatDomain              VARCHAR(MAX) = NULL, 
                                                  @chatQueue               SMALLINT     = NULL, 
                                                  @chatTime                SMALLINT     = NULL, 
                                                  @dRestrictPlay           BIT          = NULL, 
                                                  @callBackSurveyAgent     BIT          = NULL, 
                                                  @callBackSurveyClient    BIT          = NULL, 
                                                  @agts_notavailable       VARCHAR(15)  = NULL, 
                                                  @editableDtmf            BIT          = NULL, 
                                                  @prefijo                 VARCHAR(MAX) = NULL, 
                                                  @addDataCallBackReminder BIT          = NULL,
                                                  @recordHold              BIT          = NULL,
                                                  @userId                  SMALLINT     = NULL, 
                                                  @idArea                  SMALLINT     = NULL, 
                                                  @isCreating              BIT          = NULL
AS
     SET NOCOUNT ON;

     EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

     UPDATE ccInbound
       SET 
           descripcion = ISNULL(@descripcion, descripcion), 
           STATUS = ISNULL(@status, STATUS), 
           tNotas = ISNULL(CASE WHEN @chat <> 5 THEN @tNotas ELSE 10 END, tNotas), 
           tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall), 
           nMaxQue = ISNULL(@nMaxQue, nMaxQue), 
           tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait), 
           tel_MaxQueue = ISNULL(@tel_MaxQueue, tel_MaxQueue), 
           tel_outservice = ISNULL(@tel_outservice, tel_outservice), 
           tel_noct = ISNULL(@tel_noct, tel_noct), 
           bnocturno = CASE
                           WHEN ISNULL(@tel_noct, 0) = ''0''
                                OR @tel_noct = ''''
                           THEN ''0''
                           ELSE ''1''
                       END, 
           StartTimerOnHangUp = ISNULL(@StartTimerOnHangUp, StartTimerOnHangUp), 
           editableCallKey = ISNULL(@editableCallKey, editableCallKey), 
           queuePosition = ISNULL(@queuePosition, queuePosition), 
           tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack), 
           stopRecording = ISNULL(@stopRecording, stopRecording), 
           dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow), 
           OpriorityT = ISNULL(@OpriorityT, OpriorityT), 
           callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc), 
           chat = ISNULL(@chat, chat), 
           inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime), 
           maxChats = ISNULL(@maxChats, maxChats), 
           chatQueueOverflow = ISNULL(@chatQueue, ISNULL(chatQueueOverflow, 15)), 
           chatTimeOverflow = ISNULL(@chatTime, ISNULL(chatTimeOverflow, 300)), 
           startStopRecording = ISNULL(@dRestrictPlay, startStopRecording), 
           callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent), 
           callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient), 
           agts_notavailable = ISNULL(@agts_notavailable, agts_notavailable), 
           editableDtmf = ISNULL(@editableDtmf, editableDtmf), 
           prefijo = ISNULL(@prefijo, prefijo), 
           addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
           recordHold = ISNULL(@recordHold, recordHold)
     WHERE inbound_id = @inbound_id;

     IF(@chat <> 5) BEGIN
        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

        Create table #ccInboundTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )
    
        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

        DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            60, 
            3, 
            CCIT.identifierInfo,
            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCIT.dataInfo IS NOT NULL THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                    WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'') THEN
                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    WHEN CCIT.identifierInfo = ''IN_CONDUCT_SURVEY'' THEN
                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                    ELSE CCIT.dataInfo END
            ELSE '''' END, 
            (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inbound_id)
        FROM #ccInboundTable AS CCIT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
    END

     IF @chat = 5 
        BEGIN
            IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
            BEGIN
                INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                VALUES (
                    (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    40, 
                    3,'''','''', 
                    @descripcion);
            END
        END;

     IF NOT EXISTS
     (
         SELECT inbound_id
         FROM ccinbound
         WHERE inbound_id <> @inbound_id
               AND chatDomain = @chatDomain
               AND chatDomain <> ''''
     )
         BEGIN
             IF @chatDomain IS NOT NULL
                 BEGIN
                     UPDATE ccinbound
                       SET 
                           chatDomain = @chatDomain
                     WHERE inbound_id = @inbound_id;
             END;
     END;
         ELSE
         BEGIN
             UPDATE ccinbound
               SET 
                   chatDomain = ''''
             WHERE inbound_id = @inbound_id;
             RAISERROR(''Domain already in another ACD Group'', 15, 4);
     END;
     IF @ShowCalifWnd = 1
         BEGIN
             IF EXISTS
             (
                 SELECT cam_id
                 FROM ccCalifCamp
                 WHERE cam_id = @inbound_id
                       AND tipo = 0
             )
                 BEGIN
                     UPDATE ccInbound
                       SET 
                           ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
                     WHERE inbound_id = @inbound_id;
                     SELECT 1;
                     RETURN(0);
             END;
             SELECT 0;
             RETURN(0);
     END;
         ELSE
         UPDATE ccInbound
           SET 
               ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
         WHERE inbound_id = @inbound_id;
         

     SELECT 2;
     RETURN(0);
     SET NOCOUNT OFF;
        '
        EXEC(@sql)


        SET @process = '18 - ccsp_GalateacampaingManager - SP Edited, the propertie MediaType was added to SP'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateacampaingManager] 
@option           SMALLINT, 
@Activa           SMALLINT     = NULL, 
@Descripcion      VARCHAR(40) = '''', 
@IDArea           SMALLINT, 
@MirrorInbound_Id SMALLINT    = NULL, 
@frame            SMALLINT, 
@Prefijo          VARCHAR(40) = '''', 
@Type             SMALLINT, 
@userId           SMALLINT, 
@moduleId         SMALLINT    = 49,
@MediaType        SMALLINT
AS
    BEGIN
        IF(@option = 2)
            BEGIN
                IF EXISTS(select top 1 cam_id from ccCamps where cam_descripcion = @Descripcion)
                BEGIN
                    Select -1
                    return
                END
                IF OBJECT_ID(''tempdb..#Campaing'') IS NOT NULL DROP TABLE #Campaing
                CREATE TABLE #Campaing(IdCampaing INT)

                 IF OBJECT_ID(''ccInboundTableTmp'') IS NOT NULL DROP TABLE ccInboundTableTmp
                create TABLE ccInboundTableTmp  
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

                IF @type = 1
                    BEGIN
                        INSERT INTO #Campaing
                        EXEC ccsp_RIA_ABCCamps 
                             @option = @option, 
                             @Descripcion = @Descripcion, 
                             @Cam_id = ''0'', 
                             @Activa = 1, 
                             @IDArea = @IDArea, 
                             @frame = @frame, 
                             @Prefijo = @Prefijo,
                             @UserId = @userId,
                             @MediaType = @MediaType

                END
                    ELSE
                    IF @type = 0
                        BEGIN


                            INSERT INTO #Campaing
                            EXEC ccsp_RIA_ABCACDGroups 
                                 @option = @option, 
                                 @descripcion = @Descripcion, 
                                 @inbound_id = ''0'', 
                                 @idarea = @IDArea, 
                                 @frame = @frame, 
                                 @Prefijo = @Prefijo,
                                 @userid = @userId,
                                 @MediaType = @MediaType
                    END

                    IF OBJECT_ID(''ccInboundTableTmp'') IS NOT NULL DROP TABLE ccInboundTableTmp
                IF((SELECT TOP 1 IdCampaing FROM #Campaing ) > 0)
                    BEGIN
                        INSERT INTO ccRIALog
                        VALUES(
                        (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @IDArea), 
                        GETDATE(),
                        CASE
                            WHEN @type = 1
                            THEN 25
                            ELSE 26
                        END, 
                        (SELECT Login FROM ccUsers WHERE User_Id = @userId), 
                        @moduleId, 
                        '''', 
                        @Descripcion
                        )
                END
                SELECT TOP 1 IdCampaing FROM #Campaing
                IF OBJECT_ID(''tempdb..#Campaing'') IS NOT NULL DROP TABLE #Campaing
        END
    END

        '
        EXEC(@sql)

        SET @process = '19 - ccsp_GalateaDeleteCampaignAndACD - SP Edited, edited to add records to Activity Log, (Eliminar Campaña Salida (Llamada/VP/WhatsApp/IA/SMS), Eliminar Campaña Entrada (Llamada/WhatsApp))'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
            @userId           SMALLINT,
            @DeleteCamId      VARCHAR(MAX),
            @DeleteACDGroupId VARCHAR(MAX),
            @moduleId         SMALLINT = 49
        AS
        BEGIN

            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
                SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(m.meanContactTypeId, 0) AS MediaType
                INTO #CampsDelete
                FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
                inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
                left join contactMeanOut m on c.cam_id = m.camp_id
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
                SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, ISNULL(m.meanContactTypeId, 0) AS MediaType
                INTO #ACDDelete
                FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
                inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0
                left join contactMeanIn m on c.Inbound_id = m.inboundId

            IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
            begin
                select ''-1'' AS Result
                return
            end

            IF datalength(@DeleteCamId) > 0
                BEGIN

                if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                    --Borra las calificacion con reprogramacion
                    delete ccCalifCamp from ccInbound A
                    inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                    inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                    where A.cam_id in (select DeleteCamId from #CampsDelete)
                    --Borra las subcalificacion con reprogramacion
                    delete rel from ccInbound A
                    inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                    inner join ccTipoCalif C on B.calif_id=C.calif_id
                    inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                    inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                    where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

                    update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

                end

                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

                delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
                select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

                delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
                delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

                IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
                SELECT ca.AreaName,
                       GETDATE() operationDate,
                       27 operationType,
                       (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                       @moduleId module_id,
                       c.cam_descripcion value,
                       ca.AreaName AS target
                INTO #CampLog
                FROM ccRIACat_Areas ca
                Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
                WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

                DECLARE @MediaType SMALLINT;
                SET @MediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @DeleteCamId);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    (SELECT [AreaName] FROM ccRIACat_Areas AS CCRA, ccCamps AS CCA WHERE CCRA.IDArea = CCA.IDArea AND CCA.cam_id = @DeleteCamId),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    CASE 
                        WHEN @MediaType = 6 THEN 45
                        WHEN @MediaType = 5 THEN 47
                        WHEN @MediaType = 4 THEN 49
                        WHEN @MediaType = 7 THEN 51
                    ELSE 43 END, 
                    3, 
                    '''',
                    '''', 
                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @DeleteCamId);


                Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)
        
                update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
                where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5
        
                update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)
        

            END
            IF datalength(@DeleteACDGroupId) > 0
                BEGIN

                if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                    begin
                        update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
                end

                IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
                SELECT DISTINCT(IDWG)
                INTO #AllWGACD
                FROM ccRIACampEspWG ce
                WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
                from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
                where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
                from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
                where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

                delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
                delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


                IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
                SELECT ca.AreaName,
                        GETDATE() operationDate,
                        28 operationType,
                        (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                        @moduleId module_id,
                        i.descripcion value,
                        ca.AreaName AS target
                INTO #ACDLog
                FROM ccRIACat_Areas ca
                inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
                WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    (SELECT [AreaName] FROM ccRIACat_Areas AS CCRA, ccInbound AS CCI WHERE CCRA.IDArea = CCI.IDArea AND CCI.Inbound_id = @DeleteACDGroupId),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    CASE WHEN (SELECT [chat] FROM ccInbound WHERE Inbound_id = @DeleteACDGroupId) = 5 THEN 41 ELSE 61 END, 
                    3, 
                    '''',
                    '''', 
                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @DeleteACDGroupId);

                Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                        where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
                end
                if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
                end
                update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

                if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                    begin
                        update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
                end            
                update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        
            END

            IF datalength(@DeleteCamId) > 0
                Insert into ccRIALog Select * from #CampLog
            IF datalength(@DeleteACDGroupId) > 0
                Insert into ccRIALog Select * from #ACDLog

            SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
            UNION
            SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete
            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
        END
        '
        EXEC(@sql)

        SET @process = '20 - ccsp_UpdateACDWhatsappConfig - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña Entrada WhatsApp)'
        SET @sql = '
ALTER PROCEDURE  [dbo].[ccsp_UpdateACDWhatsappConfig]
    @ConexionInfo varchar(400),
    @inbound_id int,
    @ConnUser varchar(60),
    @tNotas int,
    @closeConversationTime tinyint,
    @ShowCalifWnd bit,
    @ExitWrapUpDisposition bit,
    @MUTimeOutClient int,
    @allowFileAttachments bit,
    @userId SMALLINT, 
    @idArea SMALLINT, 
    @isCreating BIT

    AS
    set nocount on
    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
    BEGIN

        UPDATE contactMeanIn SET ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 where inboundId = @inbound_id;

        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inbound_id, @userId= @userid

        IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

        Create table #contactMeanInTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime, answerTimeoutClient = @MUTimeOutClient, allowFileAttachments = @allowFileAttachments        
        where inboundId = @inbound_id;

        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#contactMeanInTable'';

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            CASE WHEN @isCreating = 1 THEN 40 ELSE 53 END, 
            3, 
            CMIT.identifierInfo,
            CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
                CASE
                    WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
                        CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    ELSE CMIT.dataInfo END
            ELSE '''' END, 
            (SELECT [name] FROM contactMeanIn WHERE inboundId = @inbound_id)
        FROM #contactMeanInTable AS CMIT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inbound_id, @userId = @userid;

        IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

        UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo


    END;

    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
    BEGIN
    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

        Create table #ccInboundTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd, ExitWrapUpDisposition = @ExitWrapUpDisposition where Inbound_id = @inbound_id;

        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            40, 
            3, 
            CASE 
                WHEN CCIT.identifierInfo = ''IN_WRAP_UP_TIME'' THEN ''IN_WRAP_UP_TIME_WHATS''
                WHEN CCIT.identifierInfo = ''IN_SHOW_DISPOSITIONS'' THEN ''IN_SHOW_DISPOSITIONS_WHATS'' 
                ELSE  CCIT.identifierInfo 
            END,
            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
                CASE
                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_UP_TIME'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN
                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    ELSE CCIT.dataInfo END
            ELSE '''' END, 
            (SELECT [name] FROM contactMeanIn WHERE inboundId = @inbound_id)
        FROM #ccInboundTable AS CCIT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
    END;
    SELECT @inbound_id;
    return(@inbound_id)

    set nocount off
        '
        EXEC(@sql)

        SET @process = '21 - ccsp_RIA_ABCCamps (Option 2, 3) - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña de Salida (Llamada/VP/WhatsApp/IA/SMS))'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
                    @option smallint,
                    @UserId int = null,
                    @Descripcion varchar(40) = null,
                    @Cam_id varchar(1000),
                    @Activa tinyint = null,
                    @IDArea smallint = null,
                    @frame tinyint = null, 
                    @MirrorInbound_Id smallint = null,
                    @Prefijo varchar(40) = null,
                    @MediaType int = null,
                    @isCreating int = null
                    as
                    set nocount on

                    if @option = 0
                        begin
                            select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
                            from ccCamps as CAMP with(nolock) 
                            left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
                            return(0)
                        end

                    if @option = 1 -- select Camp
                        begin
                            select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
                            prefijo as Prefijo
                            from ccCamps a1 with(nolock) 
                            inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
                            inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
                            where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
                            return(0)
                        end

                    if @option = 4 --Delete
                        begin
                            if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
                            begin
                            declare @error varchar(70)
                            Select @error=case valor when 0 then ''No es posible eliminar la campa?a, esta asociada a una especialidad''
                                else ''Campaign can not be deleted, it has an association with an ACD'' end
                            from ccsettings with(nolock) where setting_id = 27
                            raiserror (@error,18,1)     
                            return(0)
                            end

                            delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
                            insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
                            Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
                            Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
                            delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
                            delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id  
                            return(0)
                        end

                    if @option = 2 --Insert
                        begin
                        declare @new_cam_id smallint
                        declare @isAssingPortbyCam bit

                        DECLARE @CampTypeNormal INT = 1

                        if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
                            begin
                            select -1 --, ''Nombre en Uso''
                            return(0)  
                            end

                        -- ODC: la campa?a siempre esta activa
                        set @Activa = 1
                        declare @pref int
                        select  @pref = valor from ccSettings where setting_id = 201
                        if (@pref = 0)
                            set @Prefijo = ''''


                        Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
                        select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
                        case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

                        if @@rowcount = 1 BEGIN
                        select @new_cam_id = scope_identity()

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                            getDate(), 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                            CASE 
                                WHEN @MediaType = 6 THEN 44
                                WHEN @MediaType = 5 THEN 46
                                WHEN @MediaType = 4 THEN 48
                                WHEN @MediaType = 7 THEN 50
                                ELSE 42 END, 
                            3, 
                            '''',
                            '''', 
                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @new_cam_id);

                        END else
                            begin
                            select -2 --, ''Error al crear campa?a''
                            return(0)
                            end

                        if isnull(@MirrorInbound_Id, 0)<>0
                            begin
                            if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
                                begin
                                select -3 -- Error al asignar campa?a a ACD, el ACD no existe o no pertenece a la misma area
                                return(0)
                                end

                            update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
                            update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
                            end
                        set @isAssingPortbyCam=1

                        select @isAssingPortbyCam=valor from ccSettings where setting_id=232

                        if @isAssingPortbyCam=1 begin
                            insert into ccoDialerCamp (dialer_id, cam_id) 
                            select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
                        end

                        insert into ccCalifCamp (calif_id, cam_id, tipo) 
                        select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

                        update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

                        If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            begin
                            insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
                            end

                        insert into ccRIACampsGraph (cam_id, graphic_id)
                        select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

                        --inserta la lista negra por default
                        if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
                        begin
                            declare @tempId as int = 0
                            select @tempId = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
                            exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
                        end

                        --select * from cctiposlistanegra

                        select @new_cam_id
                        return(0)
                        end

                    if @option = 3 -- Update
                        begin
                            if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            insert into ccRIAGraphics (frame,type_id) values (@frame,1)

                            Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

                            DECLARE @PrevFrame SMALLINT = (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id);

                            update ccRIACampsGraph with(rowlock)
                            set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            where cam_id = @Cam_id

                            IF(@isCreating IS NOT NULL AND @isCreating = 2 AND @PrevFrame <> (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id)) BEGIN
                                DECLARE @Media INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @Cam_id);

                                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                                SELECT 
                                    (SELECT CRA.[AreaName] FROM ccRIACat_Areas AS CRA, ccCamps AS CCC WHERE CRA.IDArea = CCC.IDArea AND CCC.cam_id = @Cam_id),
                                    getDate(), 
                                    (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                                    CASE
                                        WHEN @Media = 6 THEN 55
                                        WHEN @Media = 5 THEN 56
                                        WHEN @Media = 4 THEN 57
                                        WHEN @Media = 7 THEN 58
                                        ELSE 54 END, 
                                    3, 
                                    '''',
                                    ''OUT_CALL_EDIT_ICON'', 
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @Cam_id);
                            END

                            return(0)
                        end

                        if @option = 5 --Obtener relaciones de campa?as - campa?as
                        begin
                            if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
                            (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
                            not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
                            begin
                            select -3 -- Campa?a invalida
                            return(0)
                            end
                                    
                        if @descripcion=0
                            set @descripcion = null

                        update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
                        if @@rowcount=0
                            select -4 -- Error al actualizar
                                        
                        else
                            begin
                            delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

                            end

                        return(0)
                        end

                    if @option = 6
                        begin
                            select cam_id, isnull(surveycamid,0)
                            from cccamps with(index(PK_ccCamps),nolock)
                            where cam_id = @Cam_id
                            return(0)
                        end

                    if @option = 7 -- Checa si la campa?a no tiene grabaciones y se puede modificar el prefijo
                        begin   
                            select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
                            --select 0 as Grabaciones   
                        end

                    if @option = 8 -- Checa si la campa?a tiene asignada una campa?a tipo encuesta
                        begin   
                            SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
                            from cccamps with(index(PK_ccCamps),nolock)
                            where cam_id = @Cam_id
                            return(0)
                        end

                    return(0)
                    set nocount off
        '
        EXEC(@sql)

        SET @process = '22 - ccsp_RIAUpdateCamConfig - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña de Salida (Llamada/VP/WhatsApp/IA/SMS))'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null,
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null,
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null,
@sipHdrsCfg varchar(255) = null,
@cam_inter_cancelled smallint = null,
@prefijo varchar(max) = null,
@exitAssisted bit = null,
@previewDiscard bit = null,
@rotativeAlgo tinyint = null,
@timesPreview tinyint = null,
@cam_tPreview smallint = null,
@timesDiscard tinyint = null,
@CampType int = null,
@agentCloseConversationTime SMALLINT = NULL,
@adminCloseConversationTime INT = NULL,
@ConexionInfo VARCHAR(400) = NULL,
@allowFileAttachments BIT = NULL,
@selectRotativeANI int = null,
@messagingOrder bit = null,
@autoStart bit = null,
@recordHold bit = null,
@userId                SMALLINT     = NULL, 
@idArea                SMALLINT     = NULL, 
@isCreating            SMALLINT          = NULL
as
set nocount on
DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
    DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

UPDATE ccCamps SET
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
 prefijo = isnull(@prefijo, prefijo),
 exitAssisted = isnull(@exitAssisted, exitAssisted),
 previewDiscard = isnull(@previewDiscard, previewDiscard),
 rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
 timesPreview = isnull(@timesPreview, timesPreview),
 cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
 timesDiscard = isnull(@timesDiscard, timesDiscard),
 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
 selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
 messagingOrder = isnull(@messagingorder, messagingOrder),
 autoStart = isnull(@autoStart,autoStart),
 recordHold = isnull(@recordHold, recordHold)

Where cam_id = @cam_id

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 44
                                                                        WHEN @Camptype = 5  THEN 46
                                                                        WHEN @Camptype = 4  THEN 48
                                                                        WHEN @Camptype = 7  THEN 50
                                                                        ELSE 42 END
                                                                ELSE 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 55
                                                                        WHEN @Camptype = 5  THEN 56
                                                                        WHEN @Camptype = 4  THEN 57
                                                                        WHEN @Camptype = 7  THEN 58
                                                                        ELSE 54 END
                                                                END;
    
        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

        IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
        
        DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
        DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
        
        IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
        ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''exitAssisted'');
        ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
        ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            3,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                THEN
                    CASE
                        WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                            CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
                            CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
                        ELSE
                            CCCT.identifierInfo
                        END
                ELSE
                ''''
                END,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                    WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                             WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                             WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                             ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                             WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                             WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                             ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                             ELSE ''COMMON_ASSISTED'' END

                    WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                        CASE WHEN  @CampType = 5 THEN 
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        ELSE
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                 WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                 WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                 ELSE ''T&COMMON_NONE'' END
                        END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

                    WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                 ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                 ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    
                    ELSE CCCT.dataInfo END
            ELSE '''' END, 
            CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
        FROM #ccCampsTable AS CCCT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
begin
    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
end

IF (@CampType IS NOT NULL)
BEGIN
    IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
    BEGIN
        SELECT 0
        RETURN(0)
    END

    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    Create table #contactMeanOutTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

    set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then '''' else @ConexionInfo end
    UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                              closeConversationTime = @agentCloseConversationTime, answerTimeoutClient = @adminCloseConversationTime,
                              allowFileAttachments = @allowFileAttachments
    WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

    
    IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
    
    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'', ''ConnPass'', ''connUser'') AND dataInfo = '''''''';

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        CMOT.identifierInfo,
        CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
            CASE
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                    CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    
                ELSE CMOT.dataInfo END
        ELSE '''' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    FROM #contactMeanOutTable AS CMOT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        IF(@ConexionInfo <> '''')
        BEGIN 
            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
        END
    END
END 
DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

if @cam_ShowCalifWnd = 1
begin
 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
  begin
  select 0
  return(0)
  end

 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
 where cam_id = @cam_id

 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        ''OUT_SHOW_DISPOSITIONS'',
        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
 END

 select 1
 return(0)
end

UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id

 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        ''OUT_SHOW_DISPOSITIONS'',
        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
 END

select 2
return(0)

set nocount off        
        '
        EXEC(@sql)

        SET @process = '23 - ccsp_UpdateOutWhatsappConfig - SP Edited, edited to add records to Activity Log, (Crear Campaña de Salida WhatsApp)'
        SET @sql = '
ALTER PROCEDURE  [dbo].[ccsp_UpdateOutWhatsappConfig] 
                    @ConexionInfo varchar(400),
                    @outbound_id int,
                    @descripcion varchar(400), 
                    @ConnUser varchar(60),
                    @tNotas int,
                    @closeConversationTime tinyint,
                    @ShowCalifWnd bit,
                    @ExitAssisted bit,
                    @MUTimeOutClient int,
                    @allowFileAttachments bit,
                    @userId SMALLINT, 
                    @idArea SMALLINT, 
                    @isCreating SMALLINT

                    AS
                    set nocount on
                    IF NOT EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id) BEGIN

                        INSERT INTO contactMeanOut (meanContactTypeId, name, camp_id, isActive, numMessages,conexionInfo,connUser,closeConversationTime,ConnPass,answerTimeoutClient,allowFileAttachments)
                        VALUES (5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = @outbound_id), 3, NULL, NULL, NULL, ''N/A'', NULL, NULL);

                    END

                                IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

                                Create table #contactMeanOutTable 
                                (
                                    columnInfo VARCHAR(255),
                                    dataInfo VARCHAR(255),
                                    identifierInfo VARCHAR(255)
                                )

                                EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @outbound_id, @userId= @userid


                                UPDATE contactMeanOut SET
                                    conexionInfo = @conexionInfo,
                                    connUser = @connUser,
                                    closeConversationTime = @closeConversationTime,
                                    answerTimeoutClient = @MUTimeOutClient,
                                    allowFileAttachments = @allowFileAttachments
                                WHERE camp_id = @outbound_id

                                IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';

                                DELETE FROM #contactMeanOutTable WHERE dataInfo = '''''''';

                                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                                SELECT 
                                    (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                                    getDate(), 
                                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                                    46, 
                                    3, 
                                    CMOT.identifierInfo,
                                    CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
                                        CASE
                                            WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                                                CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    
                                            ELSE CMOT.dataInfo END
                                    ELSE '''' END, 
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
                                FROM #contactMeanOutTable AS CMOT;

                                EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid;
                                IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

                                UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo

                    IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
                    BEGIN

                                IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

                                Create table #ccCampsTable 
                                (
                                    columnInfo VARCHAR(255),
                                    dataInfo VARCHAR(255),
                                    identifierInfo VARCHAR(255)
                                )

                                EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @outbound_id, @userId= @userid

                                UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitAssisted, CampType = 5 where cam_id = @outbound_id;

                                IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

                                DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'');

                                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                                SELECT 
                                    (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                                    getDate(), 
                                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                                    46, 
                                    3, 
                                    CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                                        CASE WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN ''OUT_WHATS_EXIT_ASSISTED''
                                        ELSE CCCT.identifierInfo END
                                    ELSE CCCT.identifierInfo END,
                                    CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                                        CASE
                                            WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'') THEN
                                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    
                                            ELSE CCCT.dataInfo END
                                    ELSE '''' END, 
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
                                FROM #ccCampsTable AS CCCT;

                                EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid;
                                IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

                    END;
                    SELECT @outbound_id;

                    set nocount off
        '
        EXEC(@sql)

        SET @process = '24 - ccspConfigSMSCamp - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña Salida SMS)'
        SET @sql = '
ALTER procedure [dbo].[ccspConfigSMSCamp] (@process int, @cam_id smallint,@strIDates nvarchar(max),@strFDates nvarchar(max),
	@userId				   SMALLINT, 
	@idArea				   SMALLINT, 
	@isCreating			   SMALLINT
 )
	as
	declare @i int
	declare @tempTableFDates as table (Id int,Value nvarchar(255))
	declare @tempTableIDates as table (Id int,Value nvarchar(255))

	select @i=1
	insert into @tempTableFDates select * from fn_RIASplitDelimited(@strFDates,'','')
	insert into @tempTableIDates select * from fn_RIASplitDelimited(@strIDates,'','')

	if(@process = 0) --Create SMS campaign
	begin
		while @i <= (select count(Value) from @tempTableFDates)
		begin
			insert into ccSmsSchedules (cam_id,iDate,fDate) values (@cam_id, (select cast(Value as datetime) from @tempTableIDates where Id = @i), (select cast(Value as datetime) from @tempTableFDates where Id = @i))
			set @i = @i +1
		end
	end
	if(@process = 1) -- Update SMS campaign
	begin

		declare @ccSmsSchedulesDelete table (
		cam_id	smallint,
		iDate	datetime,
		fDate	datetime,
		status int, --0 NOTHING, 2 DELETE
		schedPosition int)

		declare @ccSmsSchedulesUpdate table (
		cam_id	smallint,
		iDate	datetime,
		fDate	datetime,
		status int,
		schedPosition int)

		IF (@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)


		DECLARE @CamDesc VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
		DECLARE @Login VARCHAR(MAX) = (SELECT [Login] FROM ccUsers WHERE User_id = @userid);
		DECLARE @AreaName VARCHAR(MAX) = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea);

		INSERT INTO @ccSmsSchedulesDelete
		SELECT *, 2, ROW_NUMBER() OVER(ORDER BY iDate, fDate ) from ccSmsSchedules WHERE cam_id = @cam_id

		while @i <= (select count(Value) from @tempTableFDates)
		begin

			DECLARE @iDate NVARCHAR(255), @fDate NVARCHAR(255);
			SELECT @iDate = (select cast(Value as datetime) from @tempTableIDates where Id = @i), @fDate = (select cast(Value as datetime) from @tempTableFDates where Id = @i);

			IF(@isCreating = 1) BEGIN 
				insert into ccSmsSchedules (cam_id,iDate,fDate) values (@cam_id, @iDate, @fDate);
				
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT 
					@AreaName,
					getDate(), 
					@Login, 
					CASE WHEN @isCreating = 1 THEN 50 ELSE 58 END, 
					3, 
					''COMMON_DATE_''+CAST(@i AS varchar),
					@iDate+''&''+@fDate, 
					@CamDesc;

			END 
			ELSE BEGIN
				insert into @ccSmsSchedulesUpdate (cam_id, iDate, fDate, status, schedPosition)
				values (@cam_id, @iDate, @fDate, 1, @i);
			END

			set @i = @i +1
		end

		update A set A.status=0 from @ccSmsSchedulesDelete A
		inner join @ccSmsSchedulesUpdate B on A.cam_id=B.cam_id and A.iDate=B.iDate and A.fDate=B.fDate

		update A set A.status=0 from @ccSmsSchedulesUpdate A
		inner join @ccSmsSchedulesDelete B on A.cam_id=B.cam_id and A.iDate=B.iDate and A.fDate=B.fDate

		IF EXISTS(SELECT * FROM @ccSmsSchedulesDelete) BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				@AreaName,
				getDate(), 
				@Login, 
				CASE WHEN @isCreating = 1 THEN 50 ELSE 58 END, 
				3, 
				''COMMON_DELETE_SCHEDULE_''+CAST(SD.schedPosition AS varchar),
				CONVERT(varchar(max),SD.iDate,109)+''&''+CONVERT(varchar(max),SD.fDate,109),
				@CamDesc
			FROM @ccSmsSchedulesDelete AS SD WHERE SD.status = 2;

			DELETE ccSS 
			FROM ccSmsSchedules ccSS
			INNER JOIN @ccSmsSchedulesDelete ccSDEL ON ccSS.cam_id = ccSDEL.cam_id
			WHERE ccSDEL.iDate = ccSS.iDate AND ccSDEL.fDate = ccSS.fDate AND ccSDEL.status = 2

		END

		IF EXISTS(SELECT * FROM @ccSmsSchedulesUpdate) BEGIN

			DELETE FROM @ccSmsSchedulesUpdate WHERE status = 0;

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT 
					@AreaName,
					getDate(),
					@Login, 
					CASE WHEN @isCreating = 1 THEN 50 ELSE 58 END, 
					3, 
					''COMMON_ADD_SCHEDULE_''+CAST((schedPosition) AS varchar),
					 CONVERT(varchar(max),iDate,109)+''&''+CONVERT(varchar(max),fDate,109), 
					@CamDesc
				FROM @ccSmsSchedulesUpdate

				INSERT INTO ccSmsSchedules (cam_id, iDate, fDate)  
				SELECT cam_id, iDate, fDate FROM @ccSmsSchedulesUpdate

		END
	end
        '
        EXEC(@sql)

        SET @process = '25 - ccsp_GalateaUpdateVoiceConfiguration - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña Entrada Llamada)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
    @inboundId              smallint,
    @frame                  smallint    = null,
    @description            varchar(50) = null,
    @mediaType              tinyint     = null,
    @status                 smallint    = null,
    @tNotas                 int         = null,
    @tMaxWaitCall           smallint    = null,
    @nMaxQue                smallint    = null,
    @tel_maxwait            varchar(15) = null,
    @tel_maxqueue           varchar(15) = null,
    @tel_outservice         varchar(15) = null,
    @tel_noct               varchar(15) = null,
    @showCalifWnd           bit         = null,
    @editableCallKey        bit         = null,
    @queuePosition          bit         = null,
    @tMaxQueueCallBack      smallint    = null,
    @stopRecording          bit         = null,
    @dialPrefixOverflow     varchar(10) = null,
    @callerIdDesc           varchar(15) = null,
    @startStopRecording     bit         = null,
    @callBackSurveyAgent    bit         = null,
    @callBackSurveyClient   bit         = null,
    @editableDtmf           bit         = null,
    @addDataCallBackReminder bit        = null,
    @recordHold             bit         = null,
    @userId                 smallint    = null
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @graph_id smallint


    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
    
    DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);

    UPDATE ccInbound SET
        descripcion = ISNULL(@description, descripcion),
        chat = ISNULL(@mediaType, chat),
        Status = ISNULL(@status, Status),
        tNotas = ISNULL(@tNotas, tNotas),
        tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall),
        nMaxQue = ISNULL(@nMaxQue, nMaxQue),
        tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait),
        tel_maxqueue = ISNULL(@tel_maxqueue, tel_maxqueue),
        tel_outservice = ISNULL(@tel_outservice, tel_outservice),
        tel_noct = ISNULL(@tel_noct, tel_noct),
        bnocturno = CASE WHEN ISNULL(@tel_noct, 0) = ''0'' OR @tel_noct = '''' THEN ''0'' ELSE ''1'' END,
        editableCallKey = ISNULL(@editableCallKey, editableCallKey),
        queuePosition = ISNULL(@queuePosition, queuePosition),
        tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack),
        stopRecording = ISNULL(@stopRecording, stopRecording),
        dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow),
        callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc),
        startStopRecording = ISNULL(@startStopRecording, startStopRecording),
        callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent),
        callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient),
        editableDtmf = ISNULL(@editableDtmf, editableDtmf),
        addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
        recordHold = ISNULL(@recordHold, recordHold)
    WHERE Inbound_id = @inboundId

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable''; 

    DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        52, 
        3,
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
            CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCIT.dataInfo IS NOT NULL AND CCIT.dataInfo <> '''' THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END,
        CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    IF @frame IS NOT NULL
    BEGIN
        SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
        UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            CASE WHEN @mediaType = 5 THEN 40 ELSE 52 END, 
            3,
            '''',
            ''IN_CALL_EDIT_ICON'', 
            (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)

    END

    IF @showCalifWnd = 1
    BEGIN
        IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
            SELECT 1 [Result]
            RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
     BEGIN
        UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
     END

    SELECT 1 [Result]
    RETURN(0);

    SET NOCOUNT OFF;
END
        '
        EXEC(@sql)

        SET @process = '26 - ccsp_GalateaUpdateWhatsAppConfiguration - SP Edited, edited to add records to Activity Log, (Editar Campaña Entrada WhatsApp)'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
        @inboundId        smallint,
        @frame          smallint  = null,
        @description      varchar(50) = null,
        @mediaType        tinyint   = null,
        @status         smallint  = null,
        @number         varchar(400)= null,
        @maxAnswerTime      tinyint   = null,
        @muTimeOutClient    int     = null,
        @tNotas         int     = null,
        @exitWrapUpDisposition  bit     = null,
        @showCalifWnd     bit     = null,
        @allowFileAttachments bit    = null,
        @userId                 smallint    = null

      AS
      BEGIN
        SET NOCOUNT ON;
        DECLARE @graph_id smallint

        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId

        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

        Create table #ccInboundTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )
    
        DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);

        UPDATE ccInbound SET
          descripcion = ISNULL(@description, descripcion),
          chat = ISNULL(@mediaType, chat),
          Status = ISNULL(@status, Status),
          tNotas = ISNULL(@tNotas, tNotas),
          ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
        WHERE Inbound_id = @inboundId

        EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable''; 

        DELETE FROM #ccInboundTable WHERE columnInfo IN (''tel_maxwait'', ''tel_maxqueue'', ''tel_outservice'', ''tel_noct'');

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            53, 
            3,
            CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
            ELSE
                CCIT.identifierInfo
            END,
            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN
                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    ELSE CCIT.dataInfo END
            ELSE '''' END, 
            CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
        FROM #ccInboundTable AS CCIT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

        DECLARE @descUpdate varchar(50)
        DECLARE @statusCCInbound smallint
        select @descUpdate = ISNULL(@description, descripcion), @statusCCInbound = status from ccInbound where Inbound_id =@inboundId

        IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
          BEGIN
              INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
          values (5, @descUpdate, @inboundId, @statusCCInbound);
          END

        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
          BEGIN
          
          set @number = case when  @number is null or @number in('''',''0'') then '''' else @number end

          EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inboundId, @userId= @userId

            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

            Create table #contactMeanInTable 
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            )


          UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo)
          ,connUser=ISNULL(@number, connUser)
          ,ConnPass=ISNULL(@number, ConnPass) 
          ,closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime),
          answerTimeoutClient = ISNULL(@muTimeOutClient, answerTimeoutClient),
          allowFileAttachments = ISNULL(@allowFileAttachments, allowFileAttachments)
          where inboundId = @inboundId;

        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#contactMeanInTable'';  

        DELETE FROM #contactMeanInTable WHERE columnInfo IN (''name'')

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                53, 
                3, 
                CMIT.identifierInfo,
                CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
                    CASE
                        WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
                            CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        ELSE CMIT.dataInfo END
                ELSE '''' END, 
                (SELECT [name] FROM contactMeanIn WHERE inboundId = @inboundId)
            FROM #contactMeanInTable AS CMIT;

            EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

          update ccWhatsAppNumbers set inboundId=0 where inboundId=@inboundId
          if @number <> '''' begin
            update ccWhatsAppNumbers set inboundId=@inboundId where inboundId=0 and number=@number
          end

          END

        IF @frame IS NOT NULL
        BEGIN
          SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
          UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

          INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
          SELECT 
                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                53, 
                3,
                '''',
                ''IN_CALL_EDIT_ICON'', 
                (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
        END

        DECLARE @prevCalif BIT = (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId);

        IF @showCalifWnd = 1
          BEGIN
          IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
              BEGIN

            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
                  WHERE inbound_id = @inboundId

            IF(@prevCalif <> @showCalifWnd) BEGIN
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    53, 
                    3,
                    ''IN_SHOW_DISPOSITIONS'',
                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
            END

            SELECT 1 [Result]
            RETURN(0)
              END

              SELECT -1 [Result]
              RETURN(0)
           END
           ELSE
         BEGIN
          UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;

          IF(@prevCalif <> @showCalifWnd) BEGIN
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
                    53, 
                    3,
                    ''IN_SHOW_DISPOSITIONS'',
                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
            END
         END

         SELECT 1 [Result]
         RETURN(0)

        SET NOCOUNT OFF;
      END
        '
        EXEC(@sql)

        SET @process = '27 - ccsp_RIAUpdateCamConfigExtend - SP Edited, edited to add records to Activity Log, (Crear/Editar Campaña de Salida (Llamada/VP/WhatsApp/IA/SMS))'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
    @cam_id smallint,
    @zipCodeSchedule BIT = NULL,
    @userId SMALLINT = NULL,
    @idArea SMALLINT = NULL, 
    @isCreating SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    if exists(select * from ccCampsExtend where cam_id=@cam_id) begin

        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCampsExtend'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsExtendTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 44
                                                                        WHEN @Camptype = 5  THEN 46
                                                                        WHEN @Camptype = 4  THEN 48
                                                                        WHEN @Camptype = 7  THEN 50
                                                                        ELSE 42 END
                                                                ELSE 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 55
                                                                        WHEN @Camptype = 5  THEN 56
                                                                        WHEN @Camptype = 4  THEN 57
                                                                        WHEN @Camptype = 7  THEN 58
                                                                        ELSE 54 END
                                                                END;

        UPDATE ccCampsExtend SET
            zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule)
        Where cam_id = @cam_id  

        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsExtendTable'';

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            3, 
            CCCE.identifierInfo,
            CASE WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'') THEN
                        CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    
                    ELSE CCCE.dataInfo END
            ELSE '''' END, 
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        FROM #ccCampsExtendTable AS CCCE;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

    end
    else begin
        INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule) values (@cam_id,@zipCodeSchedule)
    end
    set nocount off
END
        '
        EXEC(@sql)

        ----------------------------------------------------------------------------------------------------------------------------
        /* End script release */
        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END