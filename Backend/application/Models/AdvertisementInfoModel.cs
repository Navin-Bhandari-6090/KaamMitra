using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class AdvertisementInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int AdvertisementId { get; set; }

        public string? Photo { get; set; } = string.Empty;


        public string? Video { get; set; } = string.Empty;


        [Required]

        public string Tittle { get; set; } = string.Empty;

        public string? UrlLink { get; set; } = string.Empty;

        [Required]
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    }
}
