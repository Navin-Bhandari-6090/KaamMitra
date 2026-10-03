using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class AdvPayQRIDDTO
    {
        [Required]
        public int QRId { get; set; }

    }
}
