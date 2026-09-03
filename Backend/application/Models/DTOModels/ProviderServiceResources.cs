using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProviderServiceResources
    {
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public IFormFile ServicePhoto { get; set; } = null!;

        [Required]
        public IFormFile ServiceVideo { get; set; } = null!;

        [Required]
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PhotoExtension { get; set; } = string.Empty;

        [Required]
        public string VideoExtension { get; set; } = string.Empty;

    }
}