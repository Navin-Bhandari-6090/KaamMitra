using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class BookinInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int BookId { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }


        public string? ProviderBookingDescription { get; set; } = string.Empty;


        [Required]
        public string UserBookingDescription { get; set; } = string.Empty;


        [Required]
        public int ServiceId { get; set; }

        [Required]
        public string ServiceName { get; set; } = string.Empty;


        [Required]
        public double Distance { get; set; }


        [Required]
        public bool ProviderApprovalStatus { get; set; }

        [Required]
        public bool UserApprovalStatus { get; set; }

        [Required]
        public bool ProviderTaskCompleteStatus { get; set; }

        [Required]
        public bool UserTaskCompleteStatus { get; set; }


        public double AdvancePaymentAmount { get; set; } = 0.0;

        [Required]
        public DateTime CreatedAt { get; set; }


        public int UserNumber { get; set; }

        [Required]
        public int ProviderNumber { get; set; }

        [Required]
        public bool RequiredAdvancePayment { get; set; }

       
        public double RatingValueUser { get; set; }


 


    

    }
}
