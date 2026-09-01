using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class LoginModel
    {
        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;


        [Required]
        public string Password { get; set; } = string.Empty;

    }
}
