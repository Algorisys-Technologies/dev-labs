/****** Object:  Table [dbo].[mtMonth]    Script Date: 07/15/2016 14:43:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtMonth](
	[Id] [numeric](18, 0) NOT NULL,
	[Month] [varchar](3) NOT NULL,
	[Quarter] [varchar](3) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  View [dbo].[vwCustomerwiseReport_PrevMOC]    Script Date: 07/14/2016 18:45:54 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCustomerwiseReport_PrevMOC]'))
DROP VIEW [dbo].[vwCustomerwiseReport_PrevMOC]
GO

/****** Object:  View [dbo].[vwCustomerwiseReport_PrevMOC]    Script Date: 07/14/2016 18:45:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[vwCustomerwiseReport_PrevMOC]

AS
SELECT    
convert(varchar(50),m.quarter + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) QTR ,convert(varchar(50),m.month + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) Month ,  a.SecSalesId,
 CustomerCode, CustomerName,  BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,
  
                       BranchCode,  MOC,  ClusterCode,  OutletTier,   NetSalesValue,  
                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV,
                         ServiceTaxRate, ServiceTax, AdditionalMarginRate, 
                      AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory,
                       OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, 
                       OffInvoiceMthlyValue, 
                      OffInvoiceQtrlyValue, OnInvoiceFinalValue,
                       OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
FROM         mtPrevProvision a  left outer join mtmonth m on
 convert(int,substring(convert(varchar(50),a.moc),0,CHARINDEX('.',convert(varchar(50),a.moc)))) = m.Id




GO



/****** Object:  View [dbo].[vwCustomerwiseReport_CurrentMOC]    Script Date: 07/14/2016 18:45:47 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCustomerwiseReport_CurrentMOC]'))
DROP VIEW [dbo].[vwCustomerwiseReport_CurrentMOC]
GO

/****** Object:  View [dbo].[vwCustomerwiseReport_CurrentMOC]    Script Date: 07/14/2016 18:45:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vwCustomerwiseReport_CurrentMOC]

AS
SELECT    
convert(varchar(50),m.quarter + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) QTR ,convert(varchar(50),m.month + substring(convert(varchar(50),moc),CHARINDEX('.',convert(varchar(50),moc))+3,2)) Month ,  a.Id,
 CustomerCode, CustomerName,  BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode,
  
                       BranchCode,  MOC,  ClusterCode,  OutletTier,   NetSalesValue,  
                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV,
                         ServiceTaxRate, ServiceTax, AdditionalMarginRate, 
                      AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory,
                       OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, 
                       OffInvoiceMthlyValue, 
                      OffInvoiceQtrlyValue, OnInvoiceFinalValue,
                       OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
FROM         vwCalculatedProvision a  left outer join mtmonth m on
 convert(int,substring(convert(varchar(50),a.moc),0,CHARINDEX('.',convert(varchar(50),a.moc)))) = m.Id



GO




