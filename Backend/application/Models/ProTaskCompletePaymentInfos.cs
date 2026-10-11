using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ProTaskCompletePaymentInfos
    {


        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TaskCompletePaymentId { get; set; }

        [Required]
        public double PaymentAmount { get; set; }

        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;

        [Required]
        public int BookId { get; set; }

        [Required]
        public string PaymentMethod { get; set; }

        [Required]
        public string PaymentPhoto { get; set; }

   

    }
}
