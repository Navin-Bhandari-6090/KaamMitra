using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class RatingInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int RtingId { get; set; }

        //[Required]
        public int RatingReceiverNumber { get; set; } 

        //[Required]
        public int RatingGiverNumber { get; set; } 

        [Required]
        [RegularExpression(@"^(10|[1-9])$", ErrorMessage = "Rating must be a number between 1 and 10.")]
        public int RatingValue { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [StringLength(200)]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        public int BookId { get; set; }




    }
}
