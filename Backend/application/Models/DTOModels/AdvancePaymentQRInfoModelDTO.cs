using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class AdvancePaymentQRInfoModelDTO
    {
        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string ProviderEmail { get; set; }


        [Required]
        public IFormFile QRPhoto { get; set; } 

    }
}
