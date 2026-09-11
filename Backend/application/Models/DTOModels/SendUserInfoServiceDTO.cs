namespace application.Models.DTOModels
{
    public class SendUserInfoServiceDTO
    {

        public int UserNumber { get; set; }

        public string FirstName { get; set; } = string.Empty;

        public string LastName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string PhoneNumber { get; set; } = string.Empty;

        public string WhatsappPhoneNumber { get; set; } = string.Empty;

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public string Photo { get; set; } = string.Empty;

    }
}
