using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class UpdateServiceResources
    {

        [Required]
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public string ServicePhoto { get; set; } = string.Empty;

        [Required]
        public string ServiceVideo { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public int ProviderServiceId { get; set; }

    }
}
