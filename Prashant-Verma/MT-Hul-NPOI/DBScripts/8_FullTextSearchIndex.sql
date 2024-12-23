GO
CREATE FULLTEXT CATALOG MasterDataFTS
WITH ACCENT_SENSITIVITY = OFF
------------------------------------------------

CREATE FULLTEXT INDEX ON mtAdditionalMarginMaster
(RSCode, RSName, ChainName, GroupName, PriceList)
KEY INDEX [PK__mtAdditionalMargin__3214EC07970A3FA0]
ON MasterDataFTS
WITH STOPLIST = SYSTEM

------------------------------------------------------------


CREATE FULLTEXT INDEX ON mtSalesTaxMaster
(TaxCode, StateCode)
KEY INDEX [PK__mtSalesTax__3214EC07970A3FA0]
ON MasterDataFTS
WITH STOPLIST = SYSTEM

-----------------------------------------------------------------

CREATE FULLTEXT INDEX ON mtServiceTaxRateMaster
(ChainName,GroupName)
KEY INDEX [PK__mtServic__3214EC07970A3FA0]
ON MasterDataFTS
WITH STOPLIST = SYSTEM

-----------------------------------------------------------------

CREATE FULLTEXT INDEX ON MTTierBasedTOTRate
(ChainName, GroupName, OutletTier, ColorNonColor, PriceList)
KEY INDEX [PK_MTTierBasedTOTRate_1]
ON MasterDataFTS
WITH STOPLIST = SYSTEM

------------------------------------------------------------------

--CREATE FULLTEXT INDEX ON mtSecSalesReport
--(CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, 
--PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, BranchCode, 
--ClusterCode, OutletTier)
--KEY INDEX [PK_mtSecSalesReport]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM


----------------------------------------------------------------------------



--CREATE FULLTEXT INDEX ON mtMOCCalculation
--( ChainName, GroupName, ColorNonColor, TaxCode, StateCode)
--KEY INDEX [PK_mtMOCCalculation]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM


-------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_ViewCalculateGSV ON CalculateGSVView (Id)

--CREATE FULLTEXT INDEX ON CalculateGSVView
--(TaxCode, StateCode, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, 
--                      PriceList, HulOutletCode, BranchCode, ClusterCode, OutletTier)

--KEY INDEX [IX_ViewCalculateGSV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM


------------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_CalculateProvisionView ON CalculateProvisionView (Id)

--CREATE FULLTEXT INDEX ON CalculateProvisionView
--(CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
--                      HulOutletCodeName, BranchCode, BranchName, OutletSecChannel, ClusterCode, ClusterName, OutletTier, 
--                        ChainName, GroupName, ColorNonColor, TaxCode, StateCode, 
                       
--                       Cluster, FirstLetterBrand
--)

--KEY INDEX [IX_CalculateProvisionView]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM
----------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_vwPrevOnInvoiceJV ON vwPrevOnInvoiceJV (Id)

--CREATE FULLTEXT INDEX ON vwPrevOnInvoiceJV
--( MOC, GLAccount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, Type
--)

--KEY INDEX [IX_vwPrevOnInvoiceJV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

------------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_vwPrevOffInvoiceQtrlyJV ON vwPrevOffInvoiceQtrlyJV (Id)

--CREATE FULLTEXT INDEX ON vwPrevOffInvoiceQtrlyJV
--( MOC, GLAccount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, Type
--)

--KEY INDEX [IX_vwPrevOffInvoiceQtrlyJV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

------------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_vwPrevOffInvoiceMthlyJV ON vwPrevOffInvoiceMthlyJV (Id)

--CREATE FULLTEXT INDEX ON vwPrevOffInvoiceMthlyJV
--( MOC, GLAccount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, Type
--)

--KEY INDEX [IX_vwPrevOffInvoiceMthlyJV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM


------------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_vwOnInvoiceJV ON vwOnInvoiceJV (Id)

--CREATE FULLTEXT INDEX ON vwOnInvoiceJV
--( MOC, GLAccount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, Type
--)

--KEY INDEX [IX_vwOnInvoiceJV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

------------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_vwOffInvoiceMthlyJV ON vwOffInvoiceMthlyJV (Id)

--CREATE FULLTEXT INDEX ON vwOffInvoiceMthlyJV
--( MOC, GLAccount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, Type
--)

--KEY INDEX [IX_vwOffInvoiceMthlyJV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

------------------------------------------------------------------

--CREATE UNIQUE CLUSTERED INDEX IX_vwOffInvoiceQtrlyJV ON vwOffInvoiceQtrlyJV (Id)

--CREATE FULLTEXT INDEX ON vwOffInvoiceQtrlyJV
--( MOC, GLAccount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, Type
--)

--KEY INDEX [IX_vwOffInvoiceQtrlyJV]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

------------------------------------------------------------------
--create unique clustered index ix_vwAllSecSalesReport on dbo.vwAllSecSalesReport(Id)

--CREATE FULLTEXT INDEX ON vwAllSecSalesReport
--(CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, 
--PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, BranchCode, 
--ClusterCode, OutletTier)
--KEY INDEX [ix_vwAllSecSalesReport]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

-------------------------------------------------------------

--create unique clustered index ix_vwCalculatedProvision on dbo.vwCalculatedProvision(Id)

--CREATE FULLTEXT INDEX ON vwCalculatedProvision
--( CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
--                      HulOutletCodeName, BranchCode, BranchName,  OutletSecChannel, ClusterCode, OutletTier, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, TOTSubCategory, Cluster)
--KEY INDEX [ix_vwCalculatedProvision]
--ON MasterDataFTS
--WITH STOPLIST = SYSTEM

