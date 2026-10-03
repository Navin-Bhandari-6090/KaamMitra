using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class RegServicePriceUpdateDTO
    {

        [Required]
        public int ServiceId { get; set; }

        [Required]
        public double DomesticPrice { get; set; }

        [Required]
        public double DomesticPriceDiscount { get; set; }

        [Required]
        public double InternationalPrice { get; set; }

        [Required]
        public double InternationalPriceDiscount { get; set; }

    }
}
