using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class AdvancePaymentQrInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int QRId { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string ProviderEmail { get; set; }


        [Required]
        public int ProviderNumber { get; set; }

        [Required]
        public string QRPhoto { get; set; } 


    }
}
