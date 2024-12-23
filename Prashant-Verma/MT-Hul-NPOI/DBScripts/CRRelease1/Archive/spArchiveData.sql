/****** Object:  StoredProcedure [dbo].[spArchiveData]    Script Date: 07/21/2017 12:35:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spArchiveData]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spArchiveData]
GO

/****** Object:  StoredProcedure [dbo].[spArchiveData]    Script Date: 07/21/2017 12:35:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[spArchiveData] --2
     @NoOfYears int
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
  -------------Logic Here-------------------------
  Declare @RecentMOCYear int;
  SET @RecentMOCYear= (select top 1 [Year] from mtMOCStatus order by [Year] Desc);
  print @RecentMOCYear;
  
  Declare @RecentMOCMonth int;
  SET @RecentMOCMonth= (select top 1 MonthId from mtMOCStatus order by [Year] Desc, MonthId desc);
  print @RecentMOCMonth;

  Declare @ArchiveFromYear int;
  SET @ArchiveFromYear=(@RecentMOCYear-@NoOfYears);
  print @ArchiveFromYear;
  
  declare @originalTableCount int;
  declare @ArchiveTableCount int;
  
  
CREATE TABLE #MOCStatusTempTable
(
 MonthId int,
 [Year] int,
 MOC decimal(18,4)
 )
 
 Insert INTO #MOCStatusTempTable(MonthId,[Year],MOC)
 Select distinct MonthId,[YEAR],
 CAST( cast ( MonthId as varchar(2)) + '.'+cast( [YEAR] as varchar(4) ) as decimal(18,4)) 
 from mtMOCStatus where [Year] <=@ArchiveFromYear and MonthId<@RecentMOCMonth order by [YEAR] desc,MonthId desc
 
 --select * from #MOCStatusTempTable
 
 ---Move [mtMOCStatus] Data
 
insert into [MT_archive].[dbo].[mtMOCStatus] (Id, MonthId, [Year], [Status], CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
select Id, MonthId, [Year], [Status], CreatedAt, CreatedBy, UpdatedAt, UpdatedBy
from [MT_Prod].[dbo].[mtMOCStatus]
where [MT_Prod].[dbo].[mtMOCStatus].[year]<=@ArchiveFromYear 
and [MT_Prod].[dbo].[mtMOCStatus].[MonthId]<@RecentMOCMonth


SET @originalTableCount=(select COUNT(*) from [MT_Prod].[dbo].[mtMOCStatus] 
where [MT_Prod].[dbo].[mtMOCStatus].[year]<=@ArchiveFromYear
and [MT_Prod].[dbo].[mtMOCStatus].[MonthId]<@RecentMOCMonth);

SET @ArchiveTableCount=(select COUNT(*) from [MT_archive].[dbo].[mtMOCStatus] 
where [MT_archive].[dbo].[mtMOCStatus].[year]<=@ArchiveFromYear
and [MT_archive].[dbo].[mtMOCStatus].[MonthId]<@RecentMOCMonth);
			  
IF(@originalTableCount=@ArchiveTableCount)
BEGIN
delete from [MT_Prod].[dbo].[mtMOCStatus] 
where [MT_Prod].[dbo].[mtMOCStatus].[year]<=@ArchiveFromYear
and [MT_Prod].[dbo].[mtMOCStatus].[MonthId]<@RecentMOCMonth
END


---Move [mtMOCWiseStepDetails] Data


insert into [MT_archive].[dbo].[mtMOCWiseStepDetails] (Id, MonthId, [Year], StepId, [Status], ExecutionTimes, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
select Id, MonthId, [Year], StepId, [Status], ExecutionTimes, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy
from [MT_Prod].[dbo].[mtMOCWiseStepDetails]
where [MT_Prod].[dbo].[mtMOCWiseStepDetails].[year]<=@ArchiveFromYear
and [MT_Prod].[dbo].[mtMOCWiseStepDetails].[MonthId]<@RecentMOCMonth


SET @originalTableCount=(select COUNT(*) from [MT_Prod].[dbo].[mtMOCWiseStepDetails] 
where [MT_Prod].[dbo].[mtMOCWiseStepDetails].[year]<=@ArchiveFromYear
and [MT_Prod].[dbo].[mtMOCWiseStepDetails].[MonthId]<@RecentMOCMonth);

SET @ArchiveTableCount=(select COUNT(*) from [MT_archive].[dbo].[mtMOCWiseStepDetails] 
where [MT_archive].[dbo].[mtMOCWiseStepDetails].[year]<=@ArchiveFromYear
and [MT_archive].[dbo].[mtMOCWiseStepDetails].[MonthId]<@RecentMOCMonth);
			  
IF(@originalTableCount=@ArchiveTableCount)
BEGIN
delete from [MT_Prod].[dbo].[mtMOCWiseStepDetails]
where [MT_Prod].[dbo].[mtMOCWiseStepDetails].[year]<=@ArchiveFromYear
and [MT_Prod].[dbo].[mtMOCWiseStepDetails].[MonthId]<@RecentMOCMonth
END


---Move [mtPrevProvision] Data

insert into [MT_archive].[dbo].[mtPrevProvision] (SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand, IsGstApplicable)
select SecSalesId, CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName, MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory, OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue, OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand, IsGstApplicable
from [MT_Prod].[dbo].[mtPrevProvision]
where [MT_Prod].[dbo].[mtPrevProvision].MOC IN(select MOC from #MOCStatusTempTable)


SET @originalTableCount=(select COUNT(*) from [MT_Prod].[dbo].[mtPrevProvision] 
where [MT_Prod].[dbo].[mtPrevProvision].MOC IN(select MOC from #MOCStatusTempTable));

SET @ArchiveTableCount=(select COUNT(*) from [MT_archive].[dbo].[mtPrevProvision] 
where [MT_archive].[dbo].[mtPrevProvision].MOC IN(select MOC from #MOCStatusTempTable));
			  
IF(@originalTableCount=@ArchiveTableCount)
BEGIN
delete from [MT_Prod].[dbo].[mtPrevProvision]
where [MT_Prod].[dbo].[mtPrevProvision].MOC IN(select MOC from #MOCStatusTempTable)
END


---Move [mtPrevJV] Data

insert into [MT_archive].[dbo].[mtPrevJV] (Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type])
select Id, MOC, GLAccount, Amount, BranchCode, InternalOrder, GLItemText, PMHBrandCode, DistrChannel, ProfitCenter, COPACustomer, [Type]
from [MT_Prod].[dbo].[mtPrevJV]
where [MT_Prod].[dbo].[mtPrevJV].MOC IN(select MOC from #MOCStatusTempTable)


SET @originalTableCount=(select COUNT(*) from [MT_Prod].[dbo].[mtPrevJV] 
where [MT_Prod].[dbo].[mtPrevJV].MOC IN(select MOC from #MOCStatusTempTable));

SET @ArchiveTableCount=(select COUNT(*) from [MT_archive].[dbo].[mtPrevJV] 
where [MT_archive].[dbo].[mtPrevJV].MOC IN(select MOC from #MOCStatusTempTable));
			  
IF(@originalTableCount=@ArchiveTableCount)
BEGIN
delete from [MT_Prod].[dbo].[mtPrevJV]
where [MT_Prod].[dbo].[mtPrevJV].MOC IN(select MOC from #MOCStatusTempTable)
END

--TODO Audit Trial Data moving


-----------Archival data status Table Entry-----------
--insert into [MT_archive].[dbo].[bfuArchiveDataStatus] (MOC)
--select MOC from #MOCStatusTempTable

drop table #MOCStatusTempTable

  
COMMIT
    END TRY
    BEGIN CATCH
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
                ROLLBACK
END CATCH;
END










GO


