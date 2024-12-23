/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 07/21/2017 11:38:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Dashboard_CloseMOC]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Dashboard_CloseMOC]
GO

/****** Object:  StoredProcedure [dbo].[Dashboard_CloseMOC]    Script Date: 07/21/2017 11:38:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Dashboard_CloseMOC]
      @mocMonthId int,@mocYear int,@updatedAt datetime,@updatedBy varchar(100)
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
				'Status : close'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@updatedBy as UpdatedBy 
	 
      
      UPDATE mtMOCStatus
	  SET Status='Close',UpdatedAt=@updatedAt,UpdatedBy=@updatedBy
	  WHERE MonthId=@mocMonthId AND [Year]=@mocYear;
	  
	  INSERT INTO mtPrevJV(Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type])
  SELECT Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type]
  FROM mtJV where MOC=@mocNumber

  DELETE FROM mtJV where MOC=@mocNumber
  
  INSERT INTO dbo.mtPrevProvision (SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
                      HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, ChainName, 
                      GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, 
                      TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, 
                      OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand,IsGstApplicable
)
  SELECT SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, 
                      HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, ChainName, 
                      GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, 
                      TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, 
                      OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand,a.IsGstApplicable

  FROM dbo.mtMOCCalculation a inner join dbo.mtSecSalesReport b on  a.SecSalesId=b.Id where b.MOC=@mocNumber
  
  DELETE FROM mtMOCCalculation
  DELETE FROM mtSecSalesReport where MOC=@mocNumber
  
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


