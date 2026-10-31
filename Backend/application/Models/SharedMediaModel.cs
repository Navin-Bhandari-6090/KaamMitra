using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class SharedMediaModel
    {

        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int SharedMediaId { get; set; }

        [Required]
        public string MediaDescription { get; set; } = string.Empty;


        public string? ServicePhoto { get; set; } = string.Empty;


        public string? ServiceVideo { get; set; } = string.Empty;

        public string? ServiceFile { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;


        [Required]
        public int SenderNumber { get; set; }

        [Required]
        public int ReceiverNumber { get; set; }


    }
}
