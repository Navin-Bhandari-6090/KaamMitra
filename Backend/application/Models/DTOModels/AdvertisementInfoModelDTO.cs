using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class AdvertisementInfoModelDTO
    {

        public IFormFile? Photo { get; set; } = null;

        public IFormFile? Video { get; set; } = null;


        [Required]

        public string Tittle { get; set; } = string.Empty;


        public string? UrlLink { get; set; } = string.Empty;


    }
}
