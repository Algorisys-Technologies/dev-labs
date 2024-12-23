/****** Object:  StoredProcedure [dbo].[Update_mtGstMaster]    Script Date: 07/19/2017 14:57:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtGstMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtGstMaster]
GO

/****** Object:  StoredProcedure [dbo].[Update_mtGstMaster]    Script Date: 07/19/2017 14:57:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Update_mtGstMaster]
      @tblGst mtGstMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
      Delete from mtGstMaster;
      
      INSERT INTO mtGstMaster (Id,BasepackCode, GstRate, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, Operation)
      Select newid(),BasepackCode,GstRate,getdate(),@user,null,null,'I'
      from @tblGst;

 
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


