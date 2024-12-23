
/****** Object:  StoredProcedure [dbo].[Update_StepAfterUploadSecSalesReport]    Script Date: 07/14/2016 12:41:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_StepAfterUploadSecSalesReport]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_StepAfterUploadSecSalesReport]
GO


/****** Object:  StoredProcedure [dbo].[Update_StepAfterUploadSecSalesReport]    Script Date: 07/14/2016 12:41:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Update_StepAfterUploadSecSalesReport]
      @mocMonthId nvarchar(2),@mocYear nvarchar(4),@stepId varchar(20),
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
      
UPDATE mtMOCWiseStepDetails 
SET Status='NotStarted',UpdatedBy=@user ,UpdatedAt = getdate()

WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId
in (select StepId from mtStepMaster where Sequence > (select Sequence from mtStepMaster where StepId=@stepId))	
	delete from mtMOCCalculation where SecSalesId in (select Id from mtSecSalesReport where MOC=@mocMonthId+'.'+@mocYear)
	delete from mtJV where MOC=@mocMonthId +'.'+ @mocYear
	

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




/****** Object:  StoredProcedure [dbo].[Update_SetNextStepNotStarted]    Script Date: 07/14/2016 12:41:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_SetNextStepNotStarted]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_SetNextStepNotStarted]
GO


/****** Object:  StoredProcedure [dbo].[Update_SetNextStepNotStarted]    Script Date: 07/14/2016 12:41:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Update_SetNextStepNotStarted]
      @mocMonthId nvarchar(2),@mocYear nvarchar(4),@stepId varchar(20),
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
      
UPDATE mtMOCWiseStepDetails 
SET Status='NotStarted',UpdatedBy=@user ,UpdatedAt = getdate()

WHERE MonthId=@mocMonthId AND [YEAR]=@mocYear AND StepId
in (select StepId from mtStepMaster where Sequence > (select Sequence from mtStepMaster where StepId=@stepId))	
	

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


