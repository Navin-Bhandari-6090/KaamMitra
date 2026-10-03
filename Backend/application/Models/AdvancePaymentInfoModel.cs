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


        [ForeignKey("BookId")]
        public BookinInfoModel? BookingInfos { get; set; }

    }
}
