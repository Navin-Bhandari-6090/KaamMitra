using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ProviderServiceResources
    {

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public string ServicePhoto { get; set; } = string.Empty;

        [Required]
        public string ServiceVideo { get; set; } = string.Empty;

        [Required]
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [ForeignKey("ProviderServiceId")]
        public ProviderServices? ProviderServices { get; set; }

        [ForeignKey("Email")]
        public UserInfo? Users { get; set; }

    }
}
