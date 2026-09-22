using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class SendBookingInfoUserDTO
    {

        [Required]
        [StringLength(1000)]
        public string UserAddress { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string UserPhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string UserWhatsappPhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string ProviderAddress { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string ProviderPhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        [RegularExpression(@"^\+\d+$", ErrorMessage = "Phone number must start with '+' followed by digits only.")]
        public string ProviderWhatsappPhoneNumber { get; set; } = string.Empty;

        [Required]
        public int ProviderNumber { get; set; }


        [Required]
        public int UserNumber { get; set; }


        [Required]
        public double UserLatitude { get; set; }

        [Required]
        public double UserLongitude { get; set; }

        [Required]
        public double ProviderLatitude { get; set; }

        [Required]
        public double ProviderLongitude { get; set; }

        [Required]
        public int BookId { get; set; }

        public DateTime? StartDate { get; set; }

     
        public DateTime? EndDate { get; set; }


        public string? ProviderBookingDescription { get; set; } = string.Empty;


        [Required]
        public string UserBookingDescription { get; set; } = string.Empty;


        [Required]
        [StringLength(200)]
        public string ServiceName { get; set; }


        [Required]
        public double Distance { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string ProviderEmail { get; set; }

        [Required]
        public bool ProviderApprovalStatus { get; set; }

        [Required]
        public bool UserApprovalStatus { get; set; }

        [Required]
        public bool ProviderTaskCompleteStatus { get; set; }

        [Required]
        public bool UserTaskCompleteStatus { get; set; }


        public double? AdvancePaymentAmount { get; set; } = 0.0;

        [Required]
        public DateTime CreatedAt { get; set; }


        [Required]
        public bool RequiredAdvancePayment { get; set; }




    }
}
