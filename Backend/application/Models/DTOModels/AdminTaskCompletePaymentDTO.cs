namespace application.Models.DTOModels
{
    public class AdminTaskCompletePaymentDTO
    {
        public TaskCompletePaymentInfoDTO? PaymentInfo { get; set; }
        public SendBookingInfoUserDTO? BookingInfo { get; set; }
    }
}
