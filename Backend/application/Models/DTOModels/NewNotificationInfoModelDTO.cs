using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class NewNotificationInfoModelDTO
    {

        [Required]
        public int ReceiverNumber { get; set; }

        [Required]
        public bool Status { get; set; }

    }
}
