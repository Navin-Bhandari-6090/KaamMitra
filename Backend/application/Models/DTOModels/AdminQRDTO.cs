using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class AdminQRDTO
    {


      
        public IFormFile? DomesticQRPhoto { get; set; }

    
        public IFormFile? InternationalQRPhoto { get; set; }

    }
}
