USE [CCenterRIA]
GO
ALTER PROCEDURE [dbo].[ccsp_AIToHumanTransfer]
		@action int = null,
		@camId int = null,
		@CallOutId int = null,
		@acdId int = null

	AS
	BEGIN 
		if @action = 1
		Begin
			select Inbound_id AS ACDToTranfer, 0 AS TransferMode , 0 AS TransferTo, '' AS TransferToExternalNumber, '' AS TransferToExternalDirectoryNumber   from ccInbound where cam_id = @camId
		end

		if @action = 2
		Begin
			select data_overflow_variables_quantum from ccoCallsOutSource where callout_id = @CallOutId
		end

		if @action = 3
		Begin
			select cci.idForNonComprehension AS ACDToTranfer, ISNULL(TransferOnFallback_Mode,1) AS TransferMode , ISNULL(TransferToHumanAgents,0) AS TransferTo, 
			ISNULL(cie.TransferOnFallback_ExternalNumber,'') AS TransferToExternalNumber,
			ISNULL(tt.tel,'') AS TransferToExternalDirectoryNumber  FROM ccInbound  AS  cci
			INNER JOIN	dbo.ccInboundExtend AS cie
			ON cie.Inbound_id = cci.Inbound_id
			LEFT JOIN dbo.telefonosTransferencia AS tt
			ON tt.numtra_id = cie.TransferOnFallback_DirectoryId
			WHERE cci.Inbound_id = @acdId
		end

		if @action = 4
		Begin
			select cci.idForSuccessfulTransaction AS ACDToTranfer, ISNULL(TransferOnSuccess_Mode,1) AS TransferMode , ISNULL(TransferOnSuccessfulHandling,0) AS TransferTo,
			ISNULL(cie.TransferOnSuccess_ExternalNumber,'') AS TransferToExternalNumber,
			ISNULL(tt.tel,'') AS TransferToExternalDirectoryNumber
			FROM ccInbound  AS  cci
			INNER JOIN	dbo.ccInboundExtend AS cie
			ON cie.Inbound_id = cci.Inbound_id
			LEFT JOIN dbo.telefonosTransferencia AS tt
			ON tt.numtra_id = cie.TransferOnSuccess_DirectoryId
			WHERE cci.Inbound_id = @acdId
		end
	END