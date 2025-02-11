USE [CCenterRIA]
GO

/****** Object:  Table [dbo].[ccVirtualAgent]    Script Date: 1/24/2025 4:47:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ccVirtualAgent](
	[idAgent] [int] IDENTITY(1,1) NOT NULL,
	[nameAgent] [varchar](255) NOT NULL,
	[statusAgent] [bit] NOT NULL,
	[globalAgent] [bit] NOT NULL,
	[createDateAgent] [date] NOT NULL,
	[latestUpdateDateAgent] [date] NULL,
	[descriptionAgent] [varchar](500) NOT NULL,
	[languageAgent] [int] NOT NULL,
	[rolAgent] [varchar](100) NOT NULL,
	[concurrentSessionsLimit] [int] NULL,
	[mediaType] [tinyint] NOT NULL,
	[campType] [tinyint] NOT NULL,
	[idCampaign] [tinyint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[idAgent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ccVirtualAgent] ADD  DEFAULT (getdate()) FOR [createDateAgent]
GO

ALTER TABLE [dbo].[ccVirtualAgent] ADD  DEFAULT ((0)) FOR [mediaType]
GO

ALTER TABLE [dbo].[ccVirtualAgent] ADD  DEFAULT ((0)) FOR [campType]
GO

ALTER TABLE [dbo].[ccVirtualAgent] ADD  DEFAULT ((0)) FOR [idCampaign]
GO


