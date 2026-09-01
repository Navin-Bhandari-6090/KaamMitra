using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class UserInfo
    {

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int UserNumber { get; set; }

        [Required]
        [StringLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [Key]
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
        public string Password { get; set; } = string.Empty;

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }

        public string Photo { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string Role { get; set; } = string.Empty;

        public ICollection<ProviderServices> ProviderServices { get; set; } = [];

        public ICollection<ProviderServiceResources> ProviderServicesResources { get; set; } = [];
        
    }
}
