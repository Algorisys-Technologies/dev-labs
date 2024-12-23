/****** Object:  StoredProcedure [dbo].[mtspCalculateProvision]    Script Date: 07/21/2017 17:15:15 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspCalculateProvision]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspCalculateProvision]
GO

/****** Object:  StoredProcedure [dbo].[mtspCalculateProvision]    Script Date: 07/21/2017 17:15:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspCalculateProvision] 
	@moc nvarchar(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	
	--Update Chain Name, Group Name and Color
		UPDATE
		mocCal
		SET
			ChainName = om.ChainName,
			GroupName = om.GroupName,
			ColorNonColor = om.ColorNoncolor
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 
			mocCal.SecSalesId=sec.Id 
			JOIN
			mtOutletMaster om ON 
		om.HulOutletCode=sec.HulOutletCode
		WHERE
		sec.MOC= @moc

		
	
			--Get Huggies Pack % and also do calculation
		UPDATE
		mocCal
		SET
			HuggiesPackPercentage = om.Percentage,
			HuggiesPackMargin = sec.NetSalesValue * om.Percentage
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 			
			JOIN mtHuggiesPercentageMaster om ON om.BasepackCode=sec.BasepackCode
		WHERE
		sec.MOC= @moc
		and mocCal.ChainName in (select ChainName from mtChainNameMaster where IsHuggiesAppl=1)

		
		--Update Cluster/RS Code Based on Cluster Code
		UPDATE
			mocCal
			SET
				Cluster = om.RSCode
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 			
				JOIN mtClusterRSCodeMappingMaster om ON om.clusterCode=sec.ClusterCode 
			WHERE
			sec.MOC= @moc
		
		
		--Update Additional Margin %
		UPDATE
		mocCal
		SET
			AdditionalMarginRate = om.Percentage,
			AdditionalMargin =ROUND( sec.NetSalesValue * om.Percentage,0)
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			mtAdditionalMarginMaster om ON om.RSCode=sec.CustomerCode and om.ChainName= mocCal.ChainName
			and  om.GroupName= mocCal.GroupName and  om.PriceList= sec.PriceList 
		WHERE
		sec.MOC= @moc

		--Update TOT % Subcategory Mapping
		UPDATE
		mocCal
		SET
			TOTSubCategory = om.TOTSubCategory
		FROM
			mtMOCCalculation mocCal
			JOIN
			(Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON mocCal.ChainName = subcatRate.ChainName and mocCal.GroupName = subcatRate.GroupName			
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			mtBrandWiseTOTSubCategoryMapping om ON om.PMHBrandCode=sec.PMHBrandCode and om.SalesSubCat= sec.SalesSubCat 
			and  om.PriceList= sec.PriceList 
		WHERE		
		sec.MOC= @moc

		--Update OnInvoice Rate and Value based on Subcategory
		--Todo pending for Off Mnthly and Off Qtrly	
		UPDATE
		mocCal
		SET			
			OnInvoiceRate = om.OnInvoiceRate,
			OnInvoiceValue = round((mocCal.GSV * (om.OnInvoiceRate)),4),
			OnInvoiceFinalValue = AdditionalMargin + round((mocCal.GSV * (om.OnInvoiceRate)),4),
		 --Off Mnthly
			OffInvoiceMthlyRate = om.OffInvoiceMthlyRate,
			OffInvoiceMthlyValue = round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
			OffInvoiceMthlyFinalValue = round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
		--OFF Qtrly
			OffInvoiceQtrlyRate = om.OffInvoiceQtrlyRate,
			OffInvoiceQtrlyValue = round((sec.NetSalesValue * (om.OffInvoiceQtrlyRate)),4)
			--OffInvoiceQtrlyFinalValue = OffInvoiceQtrlyValue + ServiceTax + HuggiesPackMargin
		FROM
			mtMOCCalculation mocCal			
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			mtSubCategoryTOTMaster om ON om.ChainName=mocCal.ChainName and om.GroupName= mocCal.GroupName 
			and  om.TOTSubCategory= mocCal.TOTSubCategory and sec.BranchCode=om.Branch
		WHERE
		sec.MOC= @moc


	
		---Update OnInvoice Rate and Value based on Tier Based
		UPDATE
		mocCal
		SET			
			OnInvoiceRate = om.OnInvoiceRate,
			OnInvoiceValue = round((mocCal.GSV * (om.OnInvoiceRate)),4),
			OnInvoiceFinalValue = AdditionalMargin + round((mocCal.GSV * (om.OnInvoiceRate)),4),
		 --Off Mnthly
			OffInvoiceMthlyRate = om.OffInvoiceMthlyRate,
			OffInvoiceMthlyValue = round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
			OffInvoiceMthlyFinalValue =round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
		--OFF Qtrly
			OffInvoiceQtrlyRate = om.OffInvoiceQtrlyRate,
			OffInvoiceQtrlyValue = round((sec.NetSalesValue * (om.OffInvoiceQtrlyRate)),4)
			--OffInvoiceQtrlyFinalValue = OffInvoiceQtrlyValue + ServiceTax + HuggiesPackMargin
		FROM
			mtMOCCalculation mocCal	
			JOIN
			(Select distinct ChainName, groupName from MTTierBasedTOTRate) tierRate ON mocCal.ChainName = tierRate.ChainName and mocCal.GroupName = tierRate.GroupName										
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			MTTierBasedTOTRate om ON om.ChainName=mocCal.ChainName and om.GroupName= mocCal.GroupName 
			and  om.OutletTier= sec.OutletTier  and om.ColorNonColor=mocCal.ColorNonColor and om.PriceList=sec.PriceList
		WHERE
		sec.MOC= @moc
	
		
		--Update OnInvoice Rate and Value  
		--for some special cased where instead of GSV, Net sales values needs to be considered.
		UPDATE
		mocCal
		SET			
			--OnInvoiceRate = om.OnInvoiceRate,
			OnInvoiceValue = round((sec.NetSalesValue * (OnInvoiceRate)),4),
			OnInvoiceFinalValue = AdditionalMargin + round((sec.NetSalesValue * (OnInvoiceRate)),4),
			--Off Mnthly
			OffInvoiceMthlyValue = round((sec.NetSalesValue * (OffInvoiceMthlyRate)),4),
			OffInvoiceMthlyFinalValue = round(round((sec.NetSalesValue * (OffInvoiceMthlyRate)),4),0),
			--OFF Qtrly
			OffInvoiceQtrlyValue = round((sec.NetSalesValue * (OffInvoiceQtrlyRate)),4),
			OffInvoiceQtrlyFinalValue = round(round((sec.NetSalesValue * (OffInvoiceQtrlyRate)),4),0)
						
		FROM
			mtMOCCalculation mocCal			
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 			
		WHERE
		sec.MOC= @moc and mocCal.StateCode in (Select StateCode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1) and 
		sec.IsGstApplicable=0


		
	--	--Get Service Tax Rate 
	----Todo
	UPDATE
			mocCal
			SET
				ServiceTaxRate = om.Rate,
				--calculation pending (Off invoice Quarterly * om.Rate)
				ServiceTax = OffInvoiceQtrlyValue * om.Rate				
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 			
				JOIN mtServiceTaxRateMaster om ON om.ChainName=mocCal.ChainName and om.GroupName=mocCal.GroupName
			WHERE
			sec.MOC= @moc
			
			
			--Update OffInvoiceQtrlyFinalValue 
			UPDATE
			mocCal
			SET				
				OffInvoiceQtrlyFinalValue = ROUND(OffInvoiceQtrlyValue + ServiceTax + HuggiesPackMargin,0)
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 							
			WHERE
			sec.MOC= @moc



		

END



GO


