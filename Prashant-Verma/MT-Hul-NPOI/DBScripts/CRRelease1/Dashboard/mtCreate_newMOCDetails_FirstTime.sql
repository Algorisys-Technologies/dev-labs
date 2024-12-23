/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails_FirstTime]    Script Date: 07/19/2017 16:32:58 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtCreate_newMOCDetails_FirstTime]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtCreate_newMOCDetails_FirstTime]
GO

/****** Object:  StoredProcedure [dbo].[mtCreate_newMOCDetails_FirstTime]    Script Date: 07/19/2017 16:32:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[mtCreate_newMOCDetails_FirstTime]
      @mocMonthId int,@mocYear int,@createdAt datetime,@createdBy varchar(100)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN
      
				INSERT INTO mtAuditTrailMasterData 
				SELECT newid() Id, 'MOCStatus' Entity,'MOC' KeyName,
				convert(varchar, @mocMonthId)+'.'+convert(varchar, @mocYear) as [Key], 
				'Status : open'  as Data,'U' as Operation ,
				getdate() as UpdatedAt,@createdBy as UpdatedBy 
	 
                 Insert into mtMOCStatus (Id, MonthId,[Year],[Status],CreatedAt,CreatedBy,UpdatedAt,UpdatedBy) VALUES (NEWID(), @mocMonthId,@mocYear,'Open',@createdAt,@createdBy,null,null)
                 
                 Insert into mtMOCWiseStepDetails (Id, MonthId,[Year],StepId,[Status],ExecutionTimes,CreatedAt,CreatedBy,UpdatedAt,UpdatedBy) 
                 VALUES (NEWID(), @mocMonthId,@mocYear,'UPM','Started',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'UPPM','Started',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'UPSEC','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'GSV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'PVSION','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'JV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'ExportJV','NotStarted',0,@createdAt,@createdBy,null,null),
                 (NEWID(), @mocMonthId,@mocYear,'CLSMOC','NotStarted',0,@createdAt,@createdBy,null,null)
                 
                 Insert into mtMasterDetails (StepId,DetailedStep,[Status],CreatedAt,CreatedBy,UpdatedAt,UpdatedBy)
                 VALUES ('UPM','CUSTGRP','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPM','SKU','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPM','SALESTAXRATE','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPM','GST','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','OUTLETMASTER','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','ADDMARGIN','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','SERVICETAX','Done',@createdAt,@createdBy,null,null),
                 ('UPPM','HUGGIESBAEPACK','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','CLUSTERRSCODE','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','TIERBASEDTOT','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','SUBCATMAPPING','NotStarted',@createdAt,@createdBy,null,null),
                 ('UPPM','SUBCATBASEDTOT','NotStarted',@createdAt,@createdBy,null,null)
  
  COMMIT
    END TRY
    BEGIN CATCH
      ROLLBACK
    END CATCH
END



GO


