using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UserEmailInfoModel
    {

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
