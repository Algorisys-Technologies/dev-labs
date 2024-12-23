/****** Object:  UserDefinedTableType [dbo].[mtGstMasterType]    Script Date: 07/19/2017 15:02:24 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtGstMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtGstMasterType]
GO

/****** Object:  UserDefinedTableType [dbo].[mtGstMasterType]    Script Date: 07/19/2017 15:02:24 ******/
CREATE TYPE [dbo].[mtGstMasterType] AS TABLE(
	[BasepackCode] [nvarchar](255) NULL,
	[GstRate] [decimal](5,5) NULL
)
GO


