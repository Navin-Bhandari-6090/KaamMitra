using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class RatingInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int RtingId { get; set; }

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string RatingReceiver { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string RatingGiver { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^(10|[1-9])$", ErrorMessage = "Rating must be a number between 1 and 10.")]
        public int RatingValue { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    }
}
