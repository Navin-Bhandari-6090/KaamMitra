using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProTaskComPayIDDTO
    {
        [Required]
        public int TaskCompletePaymentId { get; set; }
    }
}
