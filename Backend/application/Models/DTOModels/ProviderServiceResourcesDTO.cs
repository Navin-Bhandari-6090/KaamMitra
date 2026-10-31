using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ProviderServiceResourcesDTO
    {
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public string ServiceTitle { get; set; } = string.Empty;

        [Required]
        public IFormFile ServiceFile { get; set; } = null;

        public IFormFile? ServicePhoto { get; set; } = null!;

      
        public IFormFile? ServiceVideo { get; set; } = null!;

        [Required]
        public int ProviderServiceId { get; set; }

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

      
        public string? PhotoExtension { get; set; } = string.Empty;

    
        public string? VideoExtension { get; set; } = string.Empty;

        public string FileExtension { get; set; } = string.Empty;

    }
}