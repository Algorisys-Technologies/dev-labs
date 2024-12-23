IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[mtSecSalesReport]') 
         AND name = 'IsGstApplicable'
)
begin
ALTER TABLE mtSecSalesReport
    ADD [IsGstApplicable] bit not null DEFAULT(1)
end

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[mtPrevSecSalesReport]') 
         AND name = 'IsGstApplicable'
)
begin
ALTER TABLE mtPrevSecSalesReport
    ADD [IsGstApplicable] bit not null DEFAULT(1)
end



IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[mtTempSecSalesReport]') 
         AND name = 'IsGstApplicable'
)
begin
ALTER TABLE mtTempSecSalesReport
    ADD [IsGstApplicable] bit not null DEFAULT(1)
end



IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[mtMOCCalculation]') 
         AND name = 'IsGstApplicable'
)
begin
ALTER TABLE mtMOCCalculation
    ADD [IsGstApplicable] bit not null DEFAULT(1)
end


IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[mtPrevMOCCalculation]') 
         AND name = 'IsGstApplicable'
)
begin
ALTER TABLE mtPrevMOCCalculation
    ADD [IsGstApplicable] bit not null DEFAULT(1)
end


IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[mtPrevProvision]') 
         AND name = 'IsGstApplicable'
)
begin
ALTER TABLE mtPrevProvision
    ADD [IsGstApplicable] bit not null DEFAULT(1)
end