using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ProviderServices
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(50)]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        public string ServiceDocument { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;


        [ForeignKey("Email")]
        public UserInfo? Users { get; set; }

        public ICollection<ProviderServiceResources> ProviderServicesResources { get; set; } = [];

    }
}
