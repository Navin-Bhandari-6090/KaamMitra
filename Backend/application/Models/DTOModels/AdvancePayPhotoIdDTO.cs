using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class AdvancePayPhotoIdDTO
    {

        [Required]
        public int PaymentId { get; set; }

    }
}
