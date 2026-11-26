using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class NoticeInfoModel
    {


        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int NoticeId { get; set; }

        public int ProviderNumber { get; set; }

        public int ProviderServiceId { get; set; }

        public DateTime? CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public string Message { get; set; } = string.Empty;

    }
}
