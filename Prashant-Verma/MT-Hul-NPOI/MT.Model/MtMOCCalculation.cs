using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MtMOCCalculation : MtSecSalesReport
    { 

        public string ChainName { get; set; }
        public string GroupName { get; set; }
        public string ColorNonColor { get; set; }
        public string TaxCode { get; set; }
        public string ServiceTaxRate { get; set; }
        public decimal ServiceTax { get; set; }
        public decimal AdditionalMarginRate { get; set; }
        public decimal AdditionalMargin { get; set; }
        public decimal HuggiesPackPercentage { get; set; }
        public decimal HuggiesPackMargin { get; set; }
        public string TOTSubCategory { get; set; }
        public decimal OnInvoiceRate { get; set; }
        public decimal OffInvoiceMthlyRate { get; set; }
        public decimal OffInvoiceQtrlyRate { get; set; }
        public decimal OnInvoiceValue { get; set; }
        public decimal OffInvoiceMthlyValue { get; set; }
        public decimal OffInvoiceQtrlyValue { get; set; }
        public decimal OnInvoiceFinalValue { get; set; }
        public decimal OffInvoiceMthlyFinalValue { get; set; }
        public decimal OffInvoiceQtrlyFinalValue { get; set; }
        public string Cluster { get; set; }
        public string FirstLetterBrand { get; set; }
        public string StateCode { get; set; }
        public string SalesTaxRate { get; set; }
        public decimal GSV { get; set; }
    }
}