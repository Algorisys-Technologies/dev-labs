/****** Object:  View [dbo].[vwCalculatedProvision]    Script Date: 07/21/2017 17:25:39 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCalculatedProvision]'))
DROP VIEW [dbo].[vwCalculatedProvision]
GO

/****** Object:  View [dbo].[vwCalculatedProvision]    Script Date: 07/21/2017 17:25:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vwCalculatedProvision] 

AS
SELECT    
Id, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
                      HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, 
                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, 
                      AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, 
                      OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand,a.IsGstApplicable
FROM         dbo.mtSecSalesReport a INNER JOIN
                      dbo.mtMOCCalculation b ON a.Id = b.SecSalesId



GO


