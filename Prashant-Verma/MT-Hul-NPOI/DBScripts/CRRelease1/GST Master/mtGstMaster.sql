IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_mtGstMaster_Id]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[mtGstMaster] DROP CONSTRAINT [DF_mtGstMaster_Id]
END

GO

/****** Object:  Table [dbo].[mtGstMaster]    Script Date: 07/20/2017 11:00:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtGstMaster]') AND type in (N'U'))
DROP TABLE [dbo].[mtGstMaster]
GO

/****** Object:  Table [dbo].[mtGstMaster]    Script Date: 07/20/2017 11:00:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtGstMaster](
	[Id] [uniqueidentifier] NOT NULL,
	[BasepackCode] [nvarchar](255) NULL,
	[GstRate] [decimal](5, 5) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NOT NULL,
 CONSTRAINT [PK_mtGstMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[mtGstMaster] ADD  CONSTRAINT [DF_mtGstMaster_Id]  DEFAULT (newid()) FOR [Id]
GO


