using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateAdvanceAmountDTO
    {
        [Required]
        public double AdvancePaymentAmount { get; set; } = 0.0;

        [Required]
        public int BookId { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }

    }
}
