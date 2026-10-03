using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProTaskCompPayDTO
    {
        [Required]
        public double PaymentAmount { get; set; }

        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;

        [Required]
        public int BookId { get; set; }

        [Required]
        public string PaymentMethod { get; set; }

        [Required]
        public IFormFile PaymentPhoto { get; set; } = null;

    }
}
