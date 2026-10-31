using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class BookingInfoDTO
    {

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


   
        public bool ProviderApprovalStatus { get; set; }

        public bool UserApprovalStatus { get; set; }

        public bool ProviderTaskCompleteStatus { get; set; }

        public bool UserTaskCompleteStatus { get; set; }


        public double AdvancePaymentAmount { get; set; } = 0.0;

        public DateTime CreatedAt { get; set; }


        public int UserNumber { get; set; }

        [Required]
        public int ProviderNumber { get; set; }

      
        public bool RequiredAdvancePayment { get; set; }


        public double RatingValueUser { get; set; }

      
        public IFormFile? BookingFile { get; set; } = null;

        public IFormFile? BookingVideo { get; set; } = null;




    }
}
