using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ServiceInfoModel
    {

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int ServiceId { get; set; }

        [Required]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        public string ServiceDescription { get; set; } = string.Empty;

        [Required]
        public double DomesticPrice { get; set; }

        [Required]
        public double DomesticPriceDiscount { get; set; }

        [Required]
        public double InternationalPrice { get; set; }

        [Required]
        public double InternationalPriceDiscount { get; set; }

        [Required]
        public int NoOfRes { get; set; }


    }
}
