using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class ChatInfoModel
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ChatId { get; set; }

        [Required]
        public string Message { get; set; } = string.Empty;

        public DateTime StoreAt { get; set; } = DateTime.UtcNow;

        [Required]
        public int SenderNumber { get; set; }

        [Required]
        public int ReceiverNumber { get; set; }

    }
}
