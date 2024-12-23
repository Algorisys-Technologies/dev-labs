
/****** Object:  View [dbo].[vwCalculatedProvision]    Script Date: 06/25/2016 12:29:21 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCalculatedProvision]'))
DROP VIEW [dbo].[vwCalculatedProvision]
GO


/****** Object:  View [dbo].[vwCalculatedProvision]    Script Date: 06/25/2016 12:29:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwCalculatedProvision]WITH SCHEMABINDING

AS
SELECT    
Id, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
                      HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, 
                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, 
                      AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, 
                      OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand
FROM         dbo.mtSecSalesReport a INNER JOIN
                      dbo.mtMOCCalculation b ON a.Id = b.SecSalesId

GO



/****** Object:  View [dbo].[vwCurrentMOCJV]    Script Date: 06/29/2016 14:57:18 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwCurrentMOCJV]'))
DROP VIEW [dbo].[vwCurrentMOCJV]
GO


/****** Object:  View [dbo].[vwCurrentMOCJV]    Script Date: 06/29/2016 14:57:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[vwCurrentMOCJV]
AS

select MOC, GLAccount, Amount, ''as CrossCompanyCode, '' as ValueDate , '' as GLTaxCode, '' as CostCenter ,BranchCode, InternalOrder, '' as TransactionType, '' as GLAssignment, GLItemText, '' as TradingPartner, '' as Material, ''as PONUMBER ,PMHBrandCode,DistrChannel,''as Plant,'' as Product,ProfitCenter,''as WBSElement,''as BusinessPlace,COPACustomer,[Type]  FROM mtJV




GO



/****** Object:  View [dbo].[vwPrevMOCJV]    Script Date: 06/29/2016 14:57:37 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwPrevMOCJV]'))
DROP VIEW [dbo].[vwPrevMOCJV]
GO


/****** Object:  View [dbo].[vwPrevMOCJV]    Script Date: 06/29/2016 14:57:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vwPrevMOCJV] 
AS

select MOC, GLAccount, Amount, ''as CrossCompanyCode, '' as ValueDate , '' as GLTaxCode, '' as CostCenter ,BranchCode, InternalOrder, '' as TransactionType, '' as GLAssignment, GLItemText,'' as TradingPartner, '' as Material, ''as PONUMBER ,PMHBrandCode,DistrChannel,''as Plant,'' as Product,ProfitCenter,''as WBSElement,''as BusinessPlace,COPACustomer ,[Type] FROM mtPrevJV




GO


