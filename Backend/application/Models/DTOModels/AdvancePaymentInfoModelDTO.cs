using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class AdvancePaymentInfoModelDTO
    {

        [Required]
        public IFormFile PaymentPhoto { get; set; }


        [Required]
        public int BookId { get; set; }

    }
}
