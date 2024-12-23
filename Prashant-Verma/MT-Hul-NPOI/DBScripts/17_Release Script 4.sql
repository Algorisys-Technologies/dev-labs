
/****** Object:  Table [dbo].[mtCutomerWiseReport]    Script Date: 08/29/2016 17:11:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtCutomerWiseReport](
	[QTR] [nvarchar](10) NULL,
	[Month] [nvarchar](50) NULL,
	[GroupName] [nvarchar](250) NULL,
	[FirstLetterBrand] [nvarchar](4) NULL,
	[OnInvoiceFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyFinalValue] [decimal](18, 2) NULL,
	[MOC] [decimal](18, 4) NULL
) ON [PRIMARY]

GO


/****** Object:  StoredProcedure [dbo].[sp_UploadCustomerWiseReportDataAync]    Script Date: 08/29/2016 17:33:04 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UploadCustomerWiseReportDataAync]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_UploadCustomerWiseReportDataAync]
GO



/****** Object:  StoredProcedure [dbo].[sp_UploadCustomerWiseReportDataAync]    Script Date: 08/29/2016 17:33:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_UploadCustomerWiseReportDataAync]
      @MOC nvarchar(10)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
	DELETE from  mtCutomerWiseReport WHERE MOC=@MOC
	
	INSERT INTO mtCutomerWiseReport (QTR,Month,GroupName,FirstLetterBrand,OnInvoiceFinalValue,OffInvoiceMthlyFinalValue,OffInvoiceQtrlyFinalValue, MOC) 
	(SELECT    QTR,Month,GroupName,FirstLetterBrand,sum(OnInvoiceFinalValue) OnInvoiceFinalValue,
	sum(OffInvoiceMthlyFinalValue) OffInvoiceMthlyFinalValue,sum(OffInvoiceQtrlyFinalValue) OffInvoiceQtrlyFinalValue,@MOC
	from  vwCustomerwiseReport_CurrentMOC Where MOC=@MOC 
	Group by QTR,Month,GroupName,FirstLetterBrand)
	


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



/****** Object:  StoredProcedure [dbo].[mtspGetSubCatTOTRateDataforDownload]    Script Date: 08/30/2016 16:05:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGetSubCatTOTRateDataforDownload]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGetSubCatTOTRateDataforDownload]
GO



/****** Object:  StoredProcedure [dbo].[mtspGetSubCatTOTRateDataforDownload]    Script Date: 08/30/2016 16:05:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGetSubCatTOTRateDataforDownload] 
	@rateColumn nvarchar(50)
AS
BEGIN
DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @var VARCHAR(MAX) = '';

SELECT @var += quotename(x.Totsubcategory) + ','
FROM 
(
  SELECT DISTINCT (Totsubcategory) as Totsubcategory
  FROM mtBrandWiseTOTSubCategoryMapping
) AS x;

set @var = SUBSTRING(@var,1,len(@var)-1)
--SELECT @var;

SET @DynamicPivotQuery = 
  N'SELECT ChainName [Chain Name], GroupName [Group name (as per the base file)], Branch [BRANCH], ' + @var + 
  'FROM 
(SELECT ChainName, GroupName, Branch, '+@rateColumn+' ,Totsubcategory
FROM mtSubCategoryTOTMaster) p
PIVOT
(
sum ('+@rateColumn+')
FOR Totsubcategory IN(' + @var + ' )
) AS pvt 
order by ChainName,GroupName,Branch'
EXEC sp_executesql @DynamicPivotQuery
END








GO


