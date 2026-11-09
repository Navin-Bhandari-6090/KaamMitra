using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class LogFgtPswdDTO
    {

       


        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;


        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string PhoneNumber { get; set; } = string.Empty;


        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string WhatsappPhoneNumber { get; set; } = string.Empty;

        [Required]
        public string OldPassword { get; set; } = string.Empty;


        [Required]
        public string NewPassword { get; set; } = string.Empty;



    }
}
