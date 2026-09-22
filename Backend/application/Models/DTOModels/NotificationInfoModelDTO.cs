using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class NotificationInfoModelDTO
    {

        [Required]
        [StringLength(200)]
        public string ReceiverEmail { get; set; }

        [Required]
        public string Message { get; set; }

        [Required]
        [StringLength(200)]
        public string CurrentUserEmail { get; set; }



    }
}
