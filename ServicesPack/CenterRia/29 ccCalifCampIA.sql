use CCenterRIA;
GO
IF not exists(select * from sys.tables where name='ccCalifCampIA') begin
	CREATE TABLE dbo.ccCalifCampIA (
		calif_id smallint NOT NULL,
		cam_id   smallint NOT NULL,
		tipo     bit      NOT NULL,
		CONSTRAINT PK_ccCalifCampIA PRIMARY KEY (calif_id, cam_id, tipo)
	);	
end