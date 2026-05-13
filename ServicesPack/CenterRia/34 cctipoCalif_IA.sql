USE [CCenterRIA]

CREATE TABLE cctipoCalif_IA
	(
		calif_id smallint IDENTITY(1,1) NOT NULL,
		Name_cal varchar(150) NULL,
		Description_cal varchar(100) NULL,
		CanReprogram bit DEFAULT 0,
		autoCallback bit DEFAULT 0,
		ReturnCall smallint DEFAULT 0,
		Color varchar(15) NULL,
		AplTransfer bit DEFAULT 0,
		TransferOpcion smallint DEFAULT 0,
		DestinyIVR bit DEFAULT 0,
		DestinyIVR_camp smallint DEFAULT 0,
		DestinyIVR_number VARCHAR (20) NULL,
		DestinyIVR_directory smallint DEFAULT 0,
		AplExtDate bit DEFAULT 0,
		ExtDescription varchar(150) NULL,
		AplBlackList bit NULL,
		Cali_StatusIA bit NULL,
		DirectoryNumberFlag bit DEFAULT 1,
		CONSTRAINT cctipoCalifIA PRIMARY KEY CLUSTERED (calif_id)
	);