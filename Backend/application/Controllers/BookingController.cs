using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookingController : ControllerBase
    {
        public DatabaseController Database { get; set; }

        public BookingController(DatabaseController database)
        {
            this.Database = database;
        }

        //[Authorize(Policy = "RequireUserRole")]
        [Route("sendbookinginfouser")]
        [HttpPost]
        public async Task<IActionResult> GetBookingInfoUser(
            [FromBody] UserEmailInfoModel obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                // 2. Find current user
                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                // 3. Get all bookings of current user
                var BookingData = await Database.BookingInfos
                    .Where(x => x.UserEmail == obj.Email)
                    .OrderByDescending(x => x.CreatedAt)
                    .ToListAsync();

                // 4. Create final DTO list
                var Result = new List<SendBookingInfoUserDTO>();

                // 5. Process every booking
                foreach (var Booking in BookingData)
                {
                    // 6. Find provider using ProviderEmail
                    var Provider = await Database.UserInfos
                        .FirstOrDefaultAsync(
                            x => x.Email == Booking.ProviderEmail
                        );

                    // If provider doesn't exist, skip this booking
                    if (Provider == null)
                    {
                        continue;
                    }

                    // 7. Attach user + provider + booking information
                    var BookingDTO = new SendBookingInfoUserDTO
                    {
                        // Current user information
                        UserAddress = ExistingUser.Address,
                        UserPhoneNumber = ExistingUser.PhoneNumber,
                        UserWhatsappPhoneNumber = ExistingUser.WhatsappPhoneNumber,
                        UserNumber = ExistingUser.UserNumber,
                        UserLatitude = ExistingUser.Latitude,
                        UserLongitude = ExistingUser.Longitude,

                        // Provider information
                        ProviderAddress = Provider.Address,
                        ProviderPhoneNumber = Provider.PhoneNumber,
                        ProviderWhatsappPhoneNumber = Provider.WhatsappPhoneNumber,
                        ProviderNumber = Provider.UserNumber,
                        ProviderLatitude = Provider.Latitude,
                        ProviderLongitude = Provider.Longitude,

                        // Booking information
                        BookId = Booking.BookId,
                        StartDate = Booking.StartDate,
                        EndDate = Booking.EndDate,

                        ProviderBookingDescription =
                            Booking.ProviderBookingDescription,

                        UserBookingDescription =
                            Booking.UserBookingDescription,

                        ServiceName = Booking.ServiceName,
                        Distance = Booking.Distance,

                        UserEmail = Booking.UserEmail,
                        ProviderEmail = Booking.ProviderEmail,

                        ProviderApprovalStatus =
                            Booking.ProviderApprovalStatus,

                        UserApprovalStatus =
                            Booking.UserApprovalStatus,

                        ProviderTaskCompleteStatus =
                            Booking.ProviderTaskCompleteStatus,

                        UserTaskCompleteStatus =
                            Booking.UserTaskCompleteStatus,

                        AdvancePaymentAmount =
                            Booking.AdvancePaymentAmount,

                        CreatedAt = Booking.CreatedAt,

                        RequiredAdvancePayment=Booking.RequiredAdvancePayment,
                    };

                    // 8. Add this booking to final result
                    Result.Add(BookingDTO);
                }

                // 9. Return all booking + user + provider information
                return Ok(Result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        //[Authorize(Policy = "RequireProviderRole")]
        [Route("sendbookinginfopro")]
        [HttpPost]
        public async Task<IActionResult> GetBookingInfoPro(
            [FromBody] UserEmailInfoModel obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                // 2. Find current user
                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                // 3. Get all bookings of current user
                var BookingData = await Database.BookingInfos
                    .Where(x => x.ProviderEmail == obj.Email)
                    .OrderByDescending(x => x.CreatedAt)
                    .ToListAsync();

                // 4. Create final DTO list
                var Result = new List<SendBookingInfoUserDTO>();

                // 5. Process every booking
                foreach (var Booking in BookingData)
                {
                    // 6. Find provider using ProviderEmail
                    var Provider = await Database.UserInfos
                        .FirstOrDefaultAsync(
                            x => x.Email == Booking.ProviderEmail
                        );

                    // If provider doesn't exist, skip this booking
                    if (Provider == null)
                    {
                        continue;
                    }

                    // 7. Attach user + provider + booking information
                    var BookingDTO = new SendBookingInfoUserDTO
                    {
                        // Current user information
                        UserAddress = ExistingUser.Address,
                        UserPhoneNumber = ExistingUser.PhoneNumber,
                        UserWhatsappPhoneNumber = ExistingUser.WhatsappPhoneNumber,
                        UserNumber = ExistingUser.UserNumber,
                        UserLatitude = ExistingUser.Latitude,
                        UserLongitude = ExistingUser.Longitude,

                        // Provider information
                        ProviderAddress = Provider.Address,
                        ProviderPhoneNumber = Provider.PhoneNumber,
                        ProviderWhatsappPhoneNumber = Provider.WhatsappPhoneNumber,
                        ProviderNumber = Provider.UserNumber,
                        ProviderLatitude = Provider.Latitude,
                        ProviderLongitude = Provider.Longitude,

                        // Booking information
                        BookId = Booking.BookId,
                        StartDate = Booking.StartDate,
                        EndDate = Booking.EndDate,

                        ProviderBookingDescription =
                            Booking.ProviderBookingDescription,

                        UserBookingDescription =
                            Booking.UserBookingDescription,

                        ServiceName = Booking.ServiceName,
                        Distance = Booking.Distance,

                        UserEmail = Booking.UserEmail,
                        ProviderEmail = Booking.ProviderEmail,

                        ProviderApprovalStatus =
                            Booking.ProviderApprovalStatus,

                        UserApprovalStatus =
                            Booking.UserApprovalStatus,

                        ProviderTaskCompleteStatus =
                            Booking.ProviderTaskCompleteStatus,

                        UserTaskCompleteStatus =
                            Booking.UserTaskCompleteStatus,

                        AdvancePaymentAmount =
                            Booking.AdvancePaymentAmount,

                        CreatedAt = Booking.CreatedAt,

                        RequiredAdvancePayment = Booking.RequiredAdvancePayment,
                    };

                    // 8. Add this booking to final result
                    Result.Add(BookingDTO);
                }

                // 9. Return all booking + user + provider information
                return Ok(Result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }




        [Authorize(Policy = "RequireProviderUserRole")]
        [Route("sendnotification")]
        [HttpPost]
        public async Task<IActionResult> GetNotification([FromBody] UserEmailInfoModel obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.NotificationInfos
                    .Where(x => x.ReceiverEmail == obj.Email)
                    .OrderByDescending(x => x.Date)
                    .ToListAsync();
                return Ok(Data);

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [Route("sendnewnotification")]
        [HttpPost]
        public async Task<IActionResult> GetNewNotification([FromBody] UserEmailInfoModel obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.NewNotificationInfos
                    .Where(x => x.ReceiverEmail == obj.Email)
                    .ToListAsync();
                return Ok(Data);

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }



        [Authorize(Policy = "RequireProviderUserRole")]
        [Route("updatenewnotification")]
        [HttpPut]
        public async Task<IActionResult> UpdateNewNotification([FromBody] UserEmailInfoModel obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.NewNotificationInfos
                    .FirstOrDefaultAsync(x => x.ReceiverEmail == obj.Email);
                if (Data != null)
                {
                    Data.Status = false;
                    await Database.SaveChangesAsync();
                    return Ok();
                }
                else {
                    return StatusCode(503, "No notification data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [Authorize(Policy = "RequireProviderRole")]
        [Route("updatedate")]
        [HttpPut]
        public async Task<IActionResult> UpdateDate([FromBody] UpdateDateBookingDTO obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.UserEmail);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderEmail == obj.UserEmail);
                if (Data != null)
                {
                    Data.StartDate = DateTime.SpecifyKind(
        obj.StartDate,
        DateTimeKind.Utc
    );

                    Data.EndDate = DateTime.SpecifyKind(
                        obj.EndDate,
                        DateTimeKind.Utc
                    );
                    await Database.SaveChangesAsync();
                    return Ok();
                }
                else
                {
                    return StatusCode(503, "No booking data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(
       500,
       $"Error: {ex.Message} | Inner: {ex.InnerException?.Message}"
   );
            }
        }

        //[Authorize(Policy = "RequireProviderRole")]
        [Route("updateadvanceamount")]
        [HttpPut]
        public async Task<IActionResult> UpdateAdvanceAmount([FromBody] UpdateAdvanceAmountDTO obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.UserEmail);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderEmail == obj.UserEmail);
                if (Data != null)
                {
                    Data.AdvancePaymentAmount = obj.AdvancePaymentAmount;
                    Data.RequiredAdvancePayment = true;
                    await Database.SaveChangesAsync();
                    return Ok();
                }
                else
                {
                    return StatusCode(503, "No booking data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        //[Authorize(Policy = "RequireProviderRole")]
        [Route("updateproviderapprovalstatus")]
        [HttpPut]
        public async Task<IActionResult> UpdateProviderApprovalStatus([FromBody] UpdateProviderApprovalStatusDTO obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.UserEmail);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderEmail == obj.UserEmail);
                if (Data != null)
                {
                    if (Data.ProviderApprovalStatus == false)
                    {
                        Data.ProviderApprovalStatus = true;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else {
                        Data.ProviderApprovalStatus = false;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                
                }
                else
                {
                    return StatusCode(503, "No booking data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        //[Authorize(Policy = "RequireProviderRole")]
        [Route("proupdatetaskcompletestatus")]
        [HttpPut]
        public async Task<IActionResult> UpdateTaskCompleteStatus([FromBody] UpdateProviderApprovalStatusDTO obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.UserEmail);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderEmail == obj.UserEmail);
                if (Data != null)
                {
                    
                        Data.ProviderTaskCompleteStatus = true;
                        await Database.SaveChangesAsync();
                        return Ok();
                }
                else
                {
                    return StatusCode(503, "No booking data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        //[Authorize(Policy = "RequireProviderRole")]
        [Route("updateproviderdescp")]
        [HttpPut]
        public async Task<IActionResult> UpdateProviderDescription([FromBody] DescriptionBookingDTO obj)
        {
            try
            {
                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                var ExistingUser = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.UserEmail);

                if (ExistingUser == null)
                {
                    return StatusCode(502, "User not found.");
                }

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderEmail == obj.UserEmail);
                if (Data != null)
                {

                    Data.ProviderBookingDescription = obj.UserBookingDescription;
                    await Database.SaveChangesAsync();
                    return Ok();
                }
                else
                {
                    return StatusCode(503, "No booking data present of current user wmail.");
                }

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }










    }
}
