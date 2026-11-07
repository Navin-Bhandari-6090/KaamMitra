using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class UserInfoProfileScreenDTO
    {


        [Required]
        public int UserNumber { get; set; }

        [Required]
        [StringLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string Address { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string WhatsappPhoneNumber { get; set; } = string.Empty;

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }

        [Required]
        public string Photo { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Role { get; set; } = string.Empty;

        [Required]
        public bool LoginAccess { get; set; } = true;

        [Required]
        public bool Status { get; set; } = true;


    }
}
