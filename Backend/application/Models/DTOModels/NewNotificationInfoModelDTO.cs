using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class NewNotificationInfoModelDTO
    {

        [Required]
        [StringLength(200)]
        public string ReceiverEmail { get; set; }

        [Required]
        public bool Status { get; set; }


        [Required]
        [StringLength(200)]
        public string CurrentUserEmail { get; set; }


    }
}
