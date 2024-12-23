
/****** Object:  Table [dbo].[mtSecSalesReport]    Script Date: 06/17/2016 10:23:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtSecSalesReport](
	[Id] [uniqueidentifier] NOT NULL,
	[CustomerCode] [nvarchar](12) NULL,
	[CustomerName] [nvarchar](250) NULL,
	[OutletCategoryMaster] [nvarchar](100) NULL,
	[BasepackCode] [nvarchar](12) NULL,
	[BasepackName] [nvarchar](250) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NULL,
	[PriceList] [nvarchar](6) NULL,
	[HulOutletCode] [nvarchar](50) NULL,
	[HulOutletCodeName] [nvarchar](250) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[BranchName] [nvarchar](50) NULL,
	[MOC] [decimal](18, 4) NULL,
	[OutletSecChannel] [nvarchar](50) NULL,
	[ClusterCode] [nvarchar](5) NULL,
	[ClusterName] [nvarchar](100) NULL,
	[OutletTier] [nvarchar](50) NULL,
	[TotalSalesValue] [decimal](18, 2) NULL,
	[SalesReturnValue] [decimal](18, 2) NULL,
	[NetSalesValue] [decimal](18, 2) NULL,
	[NetSalesQty] [decimal](18, 2) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_mtSecSalesReport] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[mtSecSalesReport] ADD  CONSTRAINT [DF_mtSecSalesReport_TotalSalesValue]  DEFAULT ((0)) FOR [TotalSalesValue]
GO

ALTER TABLE [dbo].[mtSecSalesReport] ADD  CONSTRAINT [DF_mtSecSalesReport_SalesReturnValue]  DEFAULT ((0)) FOR [SalesReturnValue]
GO

ALTER TABLE [dbo].[mtSecSalesReport] ADD  CONSTRAINT [DF_mtSecSalesReport_NetSalesValue]  DEFAULT ((0)) FOR [NetSalesValue]
GO

ALTER TABLE [dbo].[mtSecSalesReport] ADD  CONSTRAINT [DF_mtSecSalesReport_NetSalesQty]  DEFAULT ((0)) FOR [NetSalesQty]
GO

ALTER TABLE [dbo].[mtSecSalesReport] ADD  CONSTRAINT [DF_mtUploadSecondarySalesMaster_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO




/****** Object:  StoredProcedure [dbo].[Update_mtSecSalesReport]    Script Date: 06/17/2016 10:22:57 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtSecSalesReport]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtSecSalesReport]
GO


/****** Object:  UserDefinedTableType [dbo].[mtSecSalesReportType]    Script Date: 06/17/2016 10:24:00 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtSecSalesReportType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtSecSalesReportType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtSecSalesReportType]    Script Date: 06/17/2016 10:24:00 ******/
CREATE TYPE [dbo].[mtSecSalesReportType] AS TABLE(
	[CustomerCode] [nvarchar](12) NULL,
	[CustomerName] [nvarchar](250) NULL,
	[OutletCategoryMaster] [nvarchar](100) NULL,
	[BasepackCode] [nvarchar](12) NULL,
	[BasepackName] [nvarchar](250) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NULL,
	[PriceList] [nvarchar](6) NULL,
	[HulOutletCode] [nvarchar](50) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[MOC] [nvarchar](8) NULL,
	[ClusterCode] [nvarchar](5) NULL,
	[OutletTier] [nvarchar](50) NULL,
	[TotalSalesValue] [decimal](18, 2) NULL,
	[SalesReturnValue] [decimal](18, 2) NULL,
	[NetSalesValue] [decimal](18, 2) NULL,
	[NetSalesQty] [decimal](18, 2) NULL
)
GO

/****** Object:  StoredProcedure [dbo].[Update_mtSecSalesReport]    Script Date: 06/17/2016 10:22:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[Update_mtSecSalesReport]
      @tblSecSalesReport mtSecSalesReportType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
   
insert into mtSecSalesReport(Id, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, BranchCode, MOC, 
                      ClusterCode, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, Operation)
            select NEWID(), c2.CustomerCode, c2.CustomerName, c2.OutletCategoryMaster, c2.BasepackCode, c2.BasepackName, c2.PMHBrandCode, PMHBrandName, c2.SalesSubCat, c2.PriceList, c2.HulOutletCode, c2.BranchCode, c2.MOC, 
                      c2.ClusterCode, c2.OutletTier, c2.TotalSalesValue, c2.SalesReturnValue, c2.NetSalesValue, c2.NetSalesQty,getdate(),@user,NULL,NULL,'I'
                      
                      FROM  @tblSecSalesReport  c2
COMMIT
    END TRY
    BEGIN CATCH
      ROLLBACK
    END CATCH
END




GO


/****** Object:  Table [dbo].[mtTempSecSalesReport]    Script Date: 06/21/2016 14:32:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtTempSecSalesReport](
	[CustomerCode] [nvarchar](12) NULL,
	[CustomerName] [nvarchar](250) NULL,
	[OutletCategoryMaster] [nvarchar](100) NULL,
	[BasepackCode] [nvarchar](12) NULL,
	[BasepackName] [nvarchar](250) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NULL,
	[PriceList] [nvarchar](20) NULL,
	[HulOutletCode] [nvarchar](50) NULL,
	[HulOutletCodeName] [nvarchar](250) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[BranchName] [nvarchar](50) NULL,
	[MOC] [decimal](18, 4) NULL,
	[OutletSecChannel] [nvarchar](50) NULL,
	[ClusterCode] [nvarchar](5) NULL,
	[ClusterName] [nvarchar](100) NULL,
	[OutletTier] [nvarchar](50) NULL,
	[TotalSalesValue] [decimal](18, 2) NULL,
	[SalesReturnValue] [decimal](18, 2) NULL,
	[NetSalesValue] [decimal](18, 2) NULL,
	[NetSalesQty] [decimal](18, 2) NULL
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[mtTempSecSalesReport] ADD  CONSTRAINT [DF_mtTempSecSalesReport1_TotalSalesValue]  DEFAULT ((0)) FOR [TotalSalesValue]
GO

ALTER TABLE [dbo].[mtTempSecSalesReport] ADD  CONSTRAINT [DF_mtTempSecSalesReport1_SalesReturnValue]  DEFAULT ((0)) FOR [SalesReturnValue]
GO

ALTER TABLE [dbo].[mtTempSecSalesReport] ADD  CONSTRAINT [DF_mtTempSecSalesReport1_NetSalesValue]  DEFAULT ((0)) FOR [NetSalesValue]
GO

ALTER TABLE [dbo].[mtTempSecSalesReport] ADD  CONSTRAINT [DF_mtTempSecSalesReport1_NetSalesQty]  DEFAULT ((0)) FOR [NetSalesQty]
GO





/****** Object:  StoredProcedure [dbo].[mtspMoveSecSalesData]    Script Date: 06/17/2016 10:22:52 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspMoveSecSalesData]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspMoveSecSalesData]
GO


/****** Object:  StoredProcedure [dbo].[mtspMoveSecSalesData]    Script Date: 06/17/2016 10:22:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspMoveSecSalesData]  
--Todo MOC as input
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

 insert into  mtSecSalesReport
(Id,CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,HulOutletCodeName, BranchCode,BranchName, MOC,OutletSecChannel, ClusterCode,ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty)
select newid(), CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,HulOutletCodeName, BranchCode,BranchName, MOC,OutletSecChannel, ClusterCode,ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty
from mtTempSecSalesReport

Truncate table mtTempSecSalesReport

END
GO





/****** Object:  StoredProcedure [dbo].[mtspMoveSecSalesData]    Script Date: 06/21/2016 14:32:03 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspMoveSecSalesData]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspMoveSecSalesData]
GO


/****** Object:  StoredProcedure [dbo].[mtspMoveSecSalesData]    Script Date: 06/21/2016 14:32:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspMoveSecSalesData]  
--Todo MOC as input
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

 insert into  mtSecSalesReport
(Id,CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,HulOutletCodeName, BranchCode,BranchName, MOC,OutletSecChannel, ClusterCode,ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty)
select newid(), CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat,LTRIM(RTRIM( replace(PriceList,'-',''))), HulOutletCode,HulOutletCodeName, BranchCode,BranchName, MOC,OutletSecChannel, ClusterCode,ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty
from mtTempSecSalesReport

Truncate table mtTempSecSalesReport

END

GO


