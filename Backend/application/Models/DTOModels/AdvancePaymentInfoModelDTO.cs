using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class AdvancePaymentInfoModelDTO
    {

        [Required]
        public IFormFile PaymentPhoto { get; set; }


        [Required]
        public int BookId { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string ProviderEmail { get; set; }

        [Required]
        public int ProviderNumber { get; set; }

    }
}
