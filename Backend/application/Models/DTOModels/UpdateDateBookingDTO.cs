using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateDateBookingDTO
    {
        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        [Required]
        public int BookId { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }

    }
}
