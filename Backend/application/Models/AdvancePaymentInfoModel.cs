using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class AdvancePaymentInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int PaymentId { get; set; }

        [Required]
        public string PaymentPhoto { get; set; } 


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

        [Required]
        public int UserNumber { get; set; }

        [ForeignKey("BookId")]
        public BookinInfoModel? BookingInfos { get; set; }




    }
}
