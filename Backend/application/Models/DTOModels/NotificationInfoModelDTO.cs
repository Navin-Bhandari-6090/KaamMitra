using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class NotificationInfoModelDTO
    {

        [Required]
        public int ReceiverNumber { get; set; }

        [Required]
        public string Message { get; set; }

    }
}
