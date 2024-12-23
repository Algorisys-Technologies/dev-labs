/****** Object:  StoredProcedure [dbo].[Dashboard_ReopenMOC]    Script Date: 07/21/2017 11:55:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_ReopenMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_ReopenMOC]
GO

/****** Object:  StoredProcedure [dbo].[Dashboard_ReopenMOC]    Script Date: 07/21/2017 11:55:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








CREATE PROCEDURE [dbo].[Dashboard_ReopenMOC]
      @mocMonthId int,@mocYear int,@updatedAt datetime,@updatedBy varchar(300)
AS

BEGIN
 
      SET NOCOUNT ON;
 BEGIN TRY
 
      BEGIN TRANSACTION
      
      DECLARE @moc varchar(10);  
DECLARE @mocNumber decimal(18,4)
SET @moc = CONVERT(varchar(10), @mocMonthId);  
SET @moc += '.';
SET @moc += CONVERT(varchar(10), @mocYear); 
SET @mocNumber=cast(@moc as decimal(18,4))
      
      				INSERT INTO mtAuditTrailMasterData 
				SELECT newid() Id, 'MOCStatus' Entity,'MOC' KeyName,
				convert(varchar, @mocMonthId)+'.'+convert(varchar, @mocYear) as [Key], 
				'Status : close|open'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@updatedBy as UpdatedBy 
	
      
      UPDATE mtMOCStatus
	  SET Status='Open',UpdatedAt=@updatedAt,UpdatedBy=@updatedBy
	  WHERE MonthId=@mocMonthId AND [Year]=@mocYear AND [Status]='Close';
	  
	  INSERT INTO mtJV (Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type])
                SELECT Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type]
  FROM mtPrevJV where MOC=@mocNumber

  DELETE FROM mtPrevJV where MOC=@mocNumber
  
  INSERT INTO mtMOCCalculation (SecSalesId, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand,IsGstApplicable)
						 SELECT SecSalesId, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand,IsGstApplicable
  FROM mtPrevProvision where MOC=@mocNumber
  
 INSERT INTO mtSecSalesReport (Id, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, Operation,IsGstApplicable)
						 SELECT SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, @updatedAt, @updatedBy, null, null, 'I',IsGstApplicable
  FROM mtPrevProvision where MOC=@mocNumber
  
  DELETE FROM mtPrevProvision where MOC=@mocNumber
  
	  COMMIT TRAN
	  


 END TRY
    
 BEGIN CATCH
 ROLLBACK TRAN
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                --ROLLBACK
 END CATCH;

END



GO


