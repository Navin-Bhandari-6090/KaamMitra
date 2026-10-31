using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class ResouIDFILEDTO
    {
        [Required]
        public int ProviderServiceResourcesId { get; set; }

        [Required]
        public IFormFile ServiceFile { get; set; } = null;

    }
}
