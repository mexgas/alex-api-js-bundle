USE [CCenterRIA]
GO

/****** Object:  Table [dbo].[ccLogAgentesDia]    Script Date: 25/01/2024 04:46:34 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ccLogAgentesDiaLast](
	[User_id] [smallint] NOT NULL,
	[TipoStatusAge_id] [tinyint] NOT NULL,
	[tStatus] [float] NULL,
	[fecha] [datetime] NOT NULL,
	[IdCampEsp] [smallint] NULL,
	[Tipo] [smallint] NULL,
	[currentStatus] [int] NULL,
	[callID] [int] NULL
) ON [PRIMARY]
GO

ALTER TABLE [ccLogAgentesDiaLast] ADD PRIMARY KEY (User_id);


ALTER TABLE [dbo].[ccLogAgentesDiaLast]  WITH CHECK ADD  CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente] FOREIGN KEY([TipoStatusAge_id])
REFERENCES [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id])
GO

ALTER TABLE [dbo].[ccLogAgentesDiaLast] CHECK CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente]
GO


