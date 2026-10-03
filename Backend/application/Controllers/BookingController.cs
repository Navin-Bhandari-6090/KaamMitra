using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BookingController : ControllerBase
    {
        public DatabaseController Database { get; set; }
        private readonly IWebHostEnvironment _environment;

        public BookingController(DatabaseController database, IWebHostEnvironment Environment)
        {
            this.Database = database;
            this._environment = Environment;
        }

        [Authorize(Policy = "RequireUserRole")]
        [Route("sendbookinginfouser")]
        [HttpPost]
        public async Task<IActionResult> GetBookingInfoUser(
            [FromBody] UserEmailInfoModel obj)
        {
            try
            {

                var userNumberClaim =
  User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                //var ExistingUser = await Database.UserInfos
                //    .FirstOrDefaultAsync(x => x.Email == obj.Email);



                // 3. Get all bookings of current user
                var BookingData = await Database.BookingInfos
                    .Where(x => x.UserNumber == currentUserNumber)
                    .OrderByDescending(x => x.CreatedAt)
                    .ToListAsync();

                if (BookingData.Count<=0)
                {
                    return StatusCode(507,"No booking data available for current user");
                }

                

                // 4. Create final DTO list
                var Result = new List<SendBookingInfoUserDTO>();

                // 5. Process every booking
                foreach (var Booking in BookingData)
                {
                    // 6. Find provider using ProviderEmail
                    var Provider = await Database.UserInfos
                        .FirstOrDefaultAsync(
                            x => x.UserNumber == Booking.ProviderNumber
                        );

                    // If provider doesn't exist, skip this booking
                    if (Provider == null)
                    {
                        continue;
                    }

                    var ServiceData = await Database.ServiceInfos.FirstOrDefaultAsync(x=>x.ServiceName==Booking.ServiceName);

                    if (ServiceData==null)
                    {
                        return StatusCode(508,"No service registered is booked");
                    }

                    // 7. Attach user + provider + booking information
                    var BookingDTO = new SendBookingInfoUserDTO
                    {
                        //  user information
                        UserAddress = user.Address,
                        UserPhoneNumber = user.PhoneNumber,
                        UserWhatsappPhoneNumber = user.WhatsappPhoneNumber,
                        UserNumber = user.UserNumber,
                        UserLatitude = user.Latitude,
                        UserLongitude = user.Longitude,

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

                        ServiceName = ServiceData.ServiceName,

                        ServiceId = ServiceData.ServiceId,

                        ProviderServiceId=Booking.ServiceId,

                        Distance = Booking.Distance,

                        UserEmail = user.Email,
                        ProviderEmail = Provider.Email,

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
                        
                        RatingValueUser=Booking.RatingValueUser,

                        DomesticPrice = ServiceData.DomesticPrice,
                        InternationalPrice = ServiceData.InternationalPrice,
                        DomesticPriceDiscount = ServiceData.DomesticPriceDiscount,
                        InternationalPriceDiscount = ServiceData.InternationalPriceDiscount

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


        [Authorize(Policy = "RequireProviderRole")]
        [Route("sendbookinginfopro")]
        [HttpPost]
        public async Task<IActionResult> GetBookingInfoPro(
            [FromBody] UserEmailInfoModel obj)
        {
            try
            {

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }



                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                // 2. Find current user
                //var ExistingUser = await Database.UserInfos
                //    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                //if (ExistingUser == null)
                //{
                //    return StatusCode(502, "User not found.");
                //}

                // 3. Get all bookings of current user
                var BookingData = await Database.BookingInfos
                    .Where(x => x.ProviderNumber == currentUserNumber)
                    .OrderByDescending(x => x.CreatedAt)
                    .ToListAsync();

                // 4. Create final DTO list
                var Result = new List<SendBookingInfoUserDTO>();

                // 5. Process every booking
                foreach (var Booking in BookingData)
                {

                    // 6. Find user using usernumber
                    var UserData = await Database.UserInfos
                        .FirstOrDefaultAsync(
                            x => x.UserNumber == Booking.UserNumber
                        );

                    // If provider doesn't exist, skip this booking
                    if (UserData == null)
                    {
                        continue;
                    }


                    var ServiceData = await Database.ServiceInfos.FirstOrDefaultAsync(x => x.ServiceName == Booking.ServiceName);

                    if (ServiceData == null)
                    {
                        return StatusCode(508, "No service registered is booked");
                    }

                    // 7. Attach user + provider + booking information
                    var BookingDTO = new SendBookingInfoUserDTO
                    {
                        //user information
                        UserAddress = UserData.Address,
                        UserPhoneNumber = UserData.PhoneNumber,
                        UserWhatsappPhoneNumber = UserData.WhatsappPhoneNumber,
                        UserNumber = UserData.UserNumber,
                        UserLatitude = UserData.Latitude,
                        UserLongitude = UserData.Longitude,

                        // Provider information
                        ProviderAddress = user.Address,
                        ProviderPhoneNumber = user.PhoneNumber,
                        ProviderWhatsappPhoneNumber = user.WhatsappPhoneNumber,
                        ProviderNumber = user.UserNumber,
                        ProviderLatitude = user.Latitude,
                        ProviderLongitude = user.Longitude,

                        // Booking information
                        BookId = Booking.BookId,
                        StartDate = Booking.StartDate,
                        EndDate = Booking.EndDate,

                        ProviderBookingDescription =
                            Booking.ProviderBookingDescription,

                        UserBookingDescription =
                            Booking.UserBookingDescription,

                        ServiceName = ServiceData.ServiceName,

                        ServiceId = ServiceData.ServiceId,

                        ProviderServiceId=Booking.ServiceId,

                        Distance = Booking.Distance,

                        UserEmail = UserData.Email,

                        ProviderEmail = user.Email,

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

                        RatingValueUser=Booking.RatingValueUser,

                        DomesticPrice = ServiceData.DomesticPrice,
                        InternationalPrice = ServiceData.InternationalPrice,
                        DomesticPriceDiscount = ServiceData.DomesticPriceDiscount,
                        InternationalPriceDiscount = ServiceData.InternationalPriceDiscount


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

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return Forbid();
                }

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
                    .Where(x => x.ReceiverNumber == currentUserNumber)
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

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return Forbid();
                }

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
                    .Where(x => x.ReceiverNumber == currentUserNumber)
                    .ToListAsync();
                return Ok(Data);

            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }



        [Authorize(Policy = "RequireforAllRole")]
        [Route("updatenewnotification")]
        [HttpPut]
        public async Task<IActionResult> UpdateNewNotification([FromBody] UserEmailInfoModel obj)
        {
            try
            {


                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                string? currentUserEmail =
    User.FindFirst(ClaimTypes.Email)?.Value;

                if (string.IsNullOrWhiteSpace(currentUserEmail))
                {
                    return Forbid();
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

                //var ExistingUser = await Database.UserInfos
                //    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                //if (ExistingUser == null)
                //{
                //    return StatusCode(502, "User not found.");
                //}

                var Data = await Database.NewNotificationInfos
                    .FirstOrDefaultAsync(x => x.ReceiverNumber == currentUserNumber);
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

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

              

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderNumber == currentUserNumber);
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

        [Authorize(Policy = "RequireProviderRole")]
        [Route("updateadvanceamount")]
        [HttpPut]
        public async Task<IActionResult> UpdateAdvanceAmount([FromBody] UpdateAdvanceAmountDTO obj)
        {
            try
            {
                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

             

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderNumber == currentUserNumber);
                if (Data != null)
                {
                    if (Data.AdvancePaymentAmount>0)
                    {
                        return StatusCode(504,"You have already change advance amount value.");
                    }

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

        [Authorize(Policy = "RequireProviderRole")]
        [Route("updateproviderapprovalstatus")]
        [HttpPut]
        public async Task<IActionResult> UpdateProviderApprovalStatus([FromBody] UpdateProviderApprovalStatusDTO obj)
        {
            try
            {
                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

         

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderNumber == currentUserNumber);
                if (Data != null)
                {
                    if (Data.ProviderApprovalStatus == false)
                    {
                        Data.ProviderApprovalStatus = true;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else 
                    {
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


        [Authorize(Policy = "RequireProviderRole")]
        [Route("updateproviderdescp")]
        [HttpPut]
        public async Task<IActionResult> UpdateProviderDescription([FromBody] DescriptionBookingDTO obj)
        {
            try
            {

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

               

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.ProviderNumber == currentUserNumber);
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

        [Authorize(Policy = "RequireUserRole")]
        [Route("updateuserrating")]
        [HttpPut]
        public async Task<IActionResult> UpdateUserRating([FromBody] RatingInfoModel obj)
        {
            try
            {

                var userNumberClaim =
      User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }

           
                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

        
                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.UserNumber == currentUserNumber);

                if (Data != null)
                {
                    var RatingData = await Database.RatingInfos.FirstOrDefaultAsync(x=>x.BookId==obj.BookId);

                    if (RatingData != null)
                    {
                        if (RatingData.RatingValue>=1 && RatingData.RatingValue<=1)
                        {
                            return StatusCode(507, "Rating value already updated");
                        }

                    }

           
                    if (Data.RatingValueUser>=1 && Data.RatingValueUser<=10)
                    {
                        return StatusCode(507, "Rating value already updated");
                    }

                    Data.RatingValueUser = obj.RatingValue;

                    var InsertRatingData = new RatingInfoModel
                    {
                        RatingReceiverNumber = Data.ProviderNumber,
                        RatingGiverNumber = currentUserNumber,
                        RatingValue = obj.RatingValue,
                        CreatedAt = DateTime.UtcNow,

                        ServiceName = obj.ServiceName,

                        BookId = obj.BookId
                    };

                    await Database.RatingInfos.AddAsync(InsertRatingData);
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




        [Authorize(Policy = "RequireUserRole")]
        [Route("updateuserapprovalstatus")]
        [HttpPut]
        public async Task<IActionResult> UpdateUserApprovalStatus([FromBody] UpdateProviderApprovalStatusDTO obj)
        {
            try
            {

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

              

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.UserNumber ==currentUserNumber);
                if (Data != null)
                {
                    if (Data.UserApprovalStatus == false)
                    {
                        Data.UserApprovalStatus = true;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else
                    {
                        Data.UserApprovalStatus = false;
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


        [Authorize(Policy = "RequireUserRole")]
        [Route("userupdatetaskcompletestatus")]
        [HttpPut]
        public async Task<IActionResult> UserUpdateTaskCompleteStatus([FromBody] UpdateProviderApprovalStatusDTO obj)
        {
            try
            {

                var userNumberClaim =
 User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // 1. Validate model
                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "The provided data is not in correct format."
                    );
                }

           

                var Data = await Database.BookingInfos
                    .FirstOrDefaultAsync(x => x.BookId == obj.BookId && x.UserNumber == currentUserNumber);
                if (Data != null)
                {
                    if (Data.UserTaskCompleteStatus == false)
                    {
                        Data.UserApprovalStatus = true;
                        await Database.SaveChangesAsync();
                        return Ok();

                    }
                    else
                    {
                        Data.UserApprovalStatus = false;
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

        [Authorize(Policy = "RequireUserRole")]
        [HttpPost]
        [Route("uploadadvancepaymentphoto")]
        [RequestSizeLimit(100 * 1024 * 1024)]
        [RequestFormLimits(MultipartBodyLengthLimit = 100 * 1024 * 1024)]
        public async Task<IActionResult> UploadAdvancePaymentPhoto(
      [FromForm] AdvancePaymentInfoModelDTO obj)
        {
            string? physicalPhotoPath = null;

            try
            {
                // =========================================================
                // 1. Validate ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in correct format."
                    );
                }

                // =========================================================
                // 2. Validate BookId
                // =========================================================

                if (obj.BookId <= 0)
                {
                    return StatusCode(
                        400,
                        "BookId is required."
                    );
                }

                // =========================================================
                // 3. Validate Payment Photo
                // =========================================================

                if (obj.PaymentPhoto == null ||
                    obj.PaymentPhoto.Length == 0)
                {
                    return StatusCode(
                        400,
                        "Payment photo is required."
                    );
                }

                // =========================================================
                // 4. Check booking
                // =========================================================

                var bookingData =
                    await Database.BookingInfos
                        .FirstOrDefaultAsync(
                            x => x.BookId == obj.BookId
                        );

                if (bookingData == null)
                {
                    return StatusCode(
                        404,
                        "No booking available with that BookId."
                    );
                }

                // =========================================================
                // 5. Check if old advance payment photo already exists
                // =========================================================

                var oldPaymentData =
                    await Database.AdvancePaymentInfos
                        .FirstOrDefaultAsync(
                            x => x.BookId == obj.BookId
                        );

                // =========================================================
                // 6. Main folder
                // =========================================================

                const string paymentFolder =
                    "uploads/advance-payment";

                // =========================================================
                // 7. Get wwwroot
                // =========================================================

                var webRootPath =
                    _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured."
                    );
                }

                // =========================================================
                // 8. Physical folder
                // =========================================================

                var physicalPaymentFolderPath =
                    Path.Combine(
                        webRootPath,
                        paymentFolder.Replace(
                            '/',
                            Path.DirectorySeparatorChar
                        )
                    );

                // =========================================================
                // 9. Create folder
                // =========================================================

                if (!Directory.Exists(
                        physicalPaymentFolderPath))
                {
                    Directory.CreateDirectory(
                        physicalPaymentFolderPath
                    );
                }

                // =========================================================
                // 10. Get extension
                // =========================================================

                var photoExtension =
                    Path.GetExtension(
                        obj.PaymentPhoto.FileName
                    )
                    .TrimStart('.')
                    .ToLowerInvariant();

                // =========================================================
                // 11. Validate extension
                // =========================================================

                var allowedPhotoExtensions =
                    new HashSet<string>(
                        StringComparer.OrdinalIgnoreCase)
                    {
                "jpg",
                "jpeg",
                "png"
                    };

                if (!allowedPhotoExtensions.Contains(
                        photoExtension))
                {
                    return StatusCode(
                        400,
                        "Invalid photo format. Only JPG, JPEG and PNG are allowed."
                    );
                }

                // =========================================================
                // 12. Generate unique filename for NEW photo
                // =========================================================

                var photoFileName =
                    $"{Guid.NewGuid():N}.{photoExtension}";

                // =========================================================
                // 13. Physical NEW photo path
                // =========================================================

                physicalPhotoPath =
                    Path.Combine(
                        physicalPaymentFolderPath,
                        photoFileName
                    );

                // =========================================================
                // 14. Save NEW photo
                // =========================================================

                await using (
                    var photoStream =
                        new FileStream(
                            physicalPhotoPath,
                            FileMode.CreateNew,
                            FileAccess.Write,
                            FileShare.None))
                {
                    await obj.PaymentPhoto
                        .CopyToAsync(photoStream);
                }

                // =========================================================
                // 15. Database path for NEW photo
                // =========================================================

                var relativePhotoPath =
                    $"/{paymentFolder}/{photoFileName}";

                // =========================================================
                // 16. Create NEW database entity
                // =========================================================

                var paymentData =
                    new AdvancePaymentInfoModel
                    {
                        PaymentPhoto =
                            relativePhotoPath,

                        BookId =
                            obj.BookId
                    };

                // =========================================================
                // 17. ADD NEW entity
                // =========================================================

                await Database
                    .AdvancePaymentInfos
                    .AddAsync(paymentData);

                // =========================================================
                // 18. Save NEW database record
                // =========================================================

                try
                {
                    await Database.SaveChangesAsync();
                }
                catch
                {
                    // -----------------------------------------------------
                    // Database save failed.
                    // Delete NEW uploaded photo.
                    // Keep OLD photo and OLD database record untouched.
                    // -----------------------------------------------------

                    try
                    {
                        if (!string.IsNullOrWhiteSpace(
                                physicalPhotoPath) &&
                            System.IO.File.Exists(
                                physicalPhotoPath))
                        {
                            System.IO.File.Delete(
                                physicalPhotoPath
                            );
                        }
                    }
                    catch
                    {
                        // Ignore cleanup failure.
                    }

                    throw;
                }

                // =========================================================
                // 19. NEW photo/database record successfully created
                // =========================================================

                // Now it is safe to remove the OLD photo and OLD record.

                if (oldPaymentData != null)
                {
                    // =====================================================
                    // 19.1 Get OLD physical photo path
                    // =====================================================

                    if (!string.IsNullOrWhiteSpace(
                            oldPaymentData.PaymentPhoto))
                    {
                        var oldPhotoRelativePath =
                            oldPaymentData.PaymentPhoto
                                .TrimStart('/')
                                .Replace(
                                    '/',
                                    Path.DirectorySeparatorChar
                                );

                        var oldPhysicalPhotoPath =
                            Path.Combine(
                                webRootPath,
                                oldPhotoRelativePath
                            );

                        // =================================================
                        // 19.2 Delete OLD physical photo
                        // =================================================

                        try
                        {
                            if (System.IO.File.Exists(
                                    oldPhysicalPhotoPath))
                            {
                                System.IO.File.Delete(
                                    oldPhysicalPhotoPath
                                );
                            }
                        }
                        catch
                        {
                            // Ignore old file cleanup failure.
                        }
                    }

                    // =====================================================
                    // 19.3 Delete OLD database record
                    // =====================================================

                    Database
                        .AdvancePaymentInfos
                        .Remove(oldPaymentData);

                    await Database.SaveChangesAsync();
                }

                // =========================================================
                // 20. Success
                // =========================================================

                if (oldPaymentData != null)
                {
                    return StatusCode(
                        200,
                        "Advance payment photo updated successfully."
                    );
                }

                return StatusCode(
                    200,
                    "Advance payment photo uploaded successfully."
                );
            }
            catch (Exception ex)
            {
                // =========================================================
                // 21. Cleanup NEW photo if unexpected error occurs
                // =========================================================

                try
                {
                    if (!string.IsNullOrWhiteSpace(
                            physicalPhotoPath) &&
                        System.IO.File.Exists(
                            physicalPhotoPath))
                    {
                        System.IO.File.Delete(
                            physicalPhotoPath
                        );
                    }
                }
                catch
                {
                    // Ignore cleanup failure.
                }

                // =========================================================
                // 22. Server error
                // =========================================================

                return StatusCode(
                    500,
                    $"An error occurred while uploading advance payment photo: {ex.Message}"
                );
            }
        }


        //[Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getadvancepaymentphoto")]
        public async Task<IActionResult> GetAdvancePaymentPhoto(
            [FromBody] BookIngIdDTO obj)
        {
            try
            {
                // =========================================================
                // 1. Validate ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "Data are not in correct format."
                    );
                }

                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.Email == obj.UserEmail
                    );

                if (userData == null)
                {
                    return StatusCode(
                        502,
                        "No user found."
                    );
                }

                var Data = await Database.AdvancePaymentInfos.FirstOrDefaultAsync(x => x.BookId == obj.BookId);
                if (Data != null)
                {

                    return Ok(Data);
                }
                else {
                    return StatusCode(503,"No booking data available.");
                }
              

            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting service photos: {ex.Message}"
                );
            }
        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getadvanceqrphoto")]
        public async Task<IActionResult> GetAdvanceQRPhoto(
          [FromBody] UserNumberDTO obj)
        {
            try
            {

                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return Forbid();
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(502, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(506, "You have been blocked by System.Contact to KaamMitra community.");
                }

                // =========================================================
                // 1. Validate ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        501,
                        "Data are not in correct format."
                    );
                }

          

                var Data = await Database.AdvancePaymentQrInfos.FirstOrDefaultAsync(x => x.ProviderNumber == obj.UserNumber);

                if (Data != null)
                {

                    return Ok(Data);
                }
                else
                {
                    return StatusCode(503, "No QR data available.");
                }


            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    $"An error occurred while getting service photos: {ex.Message}"
                );
            }
        }


        [Authorize(Policy = "RequireProviderRole")]
        [HttpPost]
        [RequestSizeLimit(52428800)] // 50 MB
        [RequestFormLimits(MultipartBodyLengthLimit = 52428800)]
        [Route("addtaskcompletepayment")]
        public async Task<IActionResult> AddTaskCompletePayment(
            [FromForm] ProTaskCompPayDTO obj)
        {
            string? newPhysicalPath = null;
            bool databaseSaved = false;

            try
            {
                Console.WriteLine("========== ADD TASK COMPLETE PAYMENT ==========");

                // =========================================================
                // 1. Validate provider from JWT
                // =========================================================

                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(
                        userNumberClaim,
                        out int currentProviderNumber))
                {
                    return StatusCode(401, "Invalid provider JWT.");
                }

                Console.WriteLine(
                    $"Provider UserNumber: {currentProviderNumber}");

                // =========================================================
                // 2. Validate ModelState
                // =========================================================

                if (!ModelState.IsValid)
                {
                    return StatusCode(
                        400,
                        "Data are not in correct format.");
                }

                // =========================================================
                // 3. Validate payment method
                // =========================================================

                if (string.IsNullOrWhiteSpace(obj.PaymentMethod))
                {
                    return StatusCode(400, "Payment method is required.");
                }

                string paymentMethod = obj.PaymentMethod.Trim();

                string folderName;

                if (paymentMethod.Equals(
                        "Domestic",
                        StringComparison.OrdinalIgnoreCase))
                {
                    paymentMethod = "Domestic";
                    folderName = "domestic";
                }
                else if (paymentMethod.Equals(
                             "International",
                             StringComparison.OrdinalIgnoreCase))
                {
                    paymentMethod = "International";
                    folderName = "international";
                }
                else
                {
                    return StatusCode(
                        400,
                        "Payment method must be Domestic or International.");
                }

                // =========================================================
                // 4. Validate payment photo
                // =========================================================

                if (obj.PaymentPhoto == null ||
                    obj.PaymentPhoto.Length == 0)
                {
                    return StatusCode(400, "Payment photo is required.");
                }

                const long maxPhotoSize = 50 * 1024 * 1024;

                if (obj.PaymentPhoto.Length > maxPhotoSize)
                {
                    return StatusCode(
                        400,
                        "Payment photo cannot exceed 50 MB.");
                }

                var extension = Path.GetExtension(
                        obj.PaymentPhoto.FileName)
                    .TrimStart('.')
                    .ToLowerInvariant();

                var allowedExtensions = new HashSet<string>(
                    StringComparer.OrdinalIgnoreCase)
        {
            "jpg",
            "jpeg",
            "png"
        };

                if (!allowedExtensions.Contains(extension))
                {
                    return StatusCode(
                        400,
                        "Invalid photo format. Only JPG, JPEG and PNG are allowed.");
                }

                // =========================================================
                // 5. Find booking belonging to this provider
                // =========================================================

                var booking = await Database.BookingInfos
                    .FirstOrDefaultAsync(x =>
                        x.BookId == obj.BookId &&
                        x.ProviderNumber == currentProviderNumber);

                if (booking == null)
                {
                    return StatusCode(
                        404,
                        "Booking not found for this provider.");
                }

                // =========================================================
                // 6. Check provider exists and login access
                // =========================================================

                var provider = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == currentProviderNumber);

                if (provider == null)
                {
                    return StatusCode(404, "Provider not found.");
                }

                if (provider.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact KaamMitra community.");
                }

                // =========================================================
                // 7. Find existing payment for this booking
                // =========================================================

                var existingPayment =
                    await Database.ProTaskCompletePaymentInfos
                        .FirstOrDefaultAsync(
                            x => x.BookId == obj.BookId);

                // =========================================================
                // 8. wwwroot and payment folder
                // =========================================================

                var webRootPath = _environment.WebRootPath;

                if (string.IsNullOrWhiteSpace(webRootPath))
                {
                    return StatusCode(
                        500,
                        "Server wwwroot folder is not configured.");
                }

                const string mainFolder =
                    "uploads/provider-task-complete-payment";

                var paymentFolder = Path.Combine(
                    webRootPath,
                    mainFolder,
                    folderName);

                if (!Directory.Exists(paymentFolder))
                {
                    Directory.CreateDirectory(paymentFolder);
                }

                // =========================================================
                // 9. Save new photo
                // =========================================================

                var fileName = $"{Guid.NewGuid():N}.{extension}";

                newPhysicalPath = Path.Combine(
                    paymentFolder,
                    fileName);

                await using (var fileStream = new FileStream(
                    newPhysicalPath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await obj.PaymentPhoto.CopyToAsync(fileStream);
                }

                string newRelativePath =
                    $"/{mainFolder}/{folderName}/{fileName}";

                Console.WriteLine($"BookId: {obj.BookId}");
                Console.WriteLine($"Payment Method: {paymentMethod}");
                Console.WriteLine($"Payment Amount: {obj.PaymentAmount}");
                Console.WriteLine($"New Photo Path: {newRelativePath}");

                // =========================================================
                // 10. Update existing payment or create a new one
                // =========================================================

                string? oldRelativePath = null;

                if (existingPayment != null)
                {
                    // Keep the old path for physical-file deletion.
                    oldRelativePath = existingPayment.PaymentPhoto;

                    existingPayment.PaymentAmount = obj.PaymentAmount;
                    existingPayment.PaymentDate = DateTime.UtcNow;
                    existingPayment.PaymentMethod = paymentMethod;
                    existingPayment.PaymentPhoto = newRelativePath;

                    await Database.SaveChangesAsync();

                    databaseSaved = true;

                    Console.WriteLine(
                        "Existing task-complete payment updated.");
                }
                else
                {
                    var newPayment = new ProTaskCompletePaymentInfos
                    {
                        PaymentAmount = obj.PaymentAmount,
                        PaymentDate = DateTime.UtcNow,
                        BookId = obj.BookId,
                        PaymentMethod = paymentMethod,
                        PaymentPhoto = newRelativePath
                    };

                    await Database.ProTaskCompletePaymentInfos
                        .AddAsync(newPayment);

                    await Database.SaveChangesAsync();

                    databaseSaved = true;

                    Console.WriteLine(
                        "New task-complete payment added.");
                }

                // =========================================================
                // 11. Delete old physical photo after database save
                // =========================================================

                if (!string.IsNullOrWhiteSpace(oldRelativePath))
                {
                    try
                    {
                        var cleanOldPath = oldRelativePath
                            .TrimStart('/', '\\')
                            .Replace('/', Path.DirectorySeparatorChar)
                            .Replace('\\', Path.DirectorySeparatorChar);

                        var oldPhysicalPath = Path.GetFullPath(
                            Path.Combine(webRootPath, cleanOldPath));

                        var uploadsRoot = Path.GetFullPath(
                            Path.Combine(webRootPath, "uploads"));

                        // Only delete files inside wwwroot/uploads.
                        var uploadsRootWithSeparator =
                            uploadsRoot.TrimEnd(
                                Path.DirectorySeparatorChar)
                            + Path.DirectorySeparatorChar;

                        if (!oldPhysicalPath.StartsWith(
                                uploadsRootWithSeparator,
                                StringComparison.OrdinalIgnoreCase))
                        {
                            Console.WriteLine(
                                "Old photo path is outside the uploads folder. Skipping deletion.");
                        }
                        else if (System.IO.File.Exists(oldPhysicalPath))
                        {
                            System.IO.File.Delete(oldPhysicalPath);

                            Console.WriteLine("Old payment photo deleted.");
                        }
                        else
                        {
                            Console.WriteLine(
                                "Old payment photo does not exist.");
                        }
                    }
                    catch (Exception fileEx)
                    {
                        // Database is already updated.
                        // Do not fail the successful payment update.
                        Console.WriteLine(
                            $"Old photo deletion error: {fileEx.Message}");
                    }
                }

                // =========================================================
                // 12. Success
                // =========================================================

                return Ok(
                    existingPayment != null
                        ? "Task-complete payment updated successfully."
                        : "Task-complete payment added successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    "========== TASK COMPLETE PAYMENT ERROR ==========");

                Console.WriteLine($"Error: {ex.Message}");
                Console.WriteLine($"StackTrace: {ex.StackTrace}");

                // Delete the newly uploaded file only if the database
                // operation did not succeed.
                if (!databaseSaved &&
                    !string.IsNullOrWhiteSpace(newPhysicalPath))
                {
                    try
                    {
                        if (System.IO.File.Exists(newPhysicalPath))
                        {
                            System.IO.File.Delete(newPhysicalPath);
                            Console.WriteLine(
                                "New photo deleted after failed operation.");
                        }
                    }
                    catch (Exception cleanupEx)
                    {
                        Console.WriteLine(
                            $"New photo cleanup error: {cleanupEx.Message}");
                    }
                }

                return StatusCode(
                    500,
                    $"An error occurred while saving task-complete payment: {ex.Message}");
            }
        }

     
[Authorize(Policy = "RequireProviderRole")]
[HttpGet]
[Route("getprovidertaskcompletepayments")]
public async Task<IActionResult> GetProviderTaskCompletePayments()
        {
            try
            {
                if (!ModelState.IsValid)
                    return StatusCode(400, "Data are not in correct format.");

                // Get current provider UserNumber / ProviderNumber from JWT
                var userNumberClaim =
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentProviderNumber))
                    return Forbid();

                Console.WriteLine(
                    $"Current Provider Number: {currentProviderNumber}"
                );

                // Check provider user
                var providerUser = await Database.UserInfos
                    .FirstOrDefaultAsync(
                        x => x.UserNumber == currentProviderNumber
                    );

                if (providerUser == null)
                    return StatusCode(404, "Provider user not found.");

                // Check login access
                if (providerUser.LoginAccess == false)
                {
                    return StatusCode(
                        506,
                        "You have been blocked by System. Contact KaamMitra community."
                    );
                }

                // Get payments whose BookId belongs
                // to a booking of the current provider.
                var paymentList = await Database.ProTaskCompletePaymentInfos
                    .Where(payment =>
                        Database.BookingInfos.Any(booking =>
                            booking.BookId == payment.BookId &&
                            booking.ProviderNumber == currentProviderNumber
                        )
                    )
                    .ToListAsync();

                if (paymentList == null || paymentList.Count == 0)
                {
                    return StatusCode(
                        404,
                        "No task complete payment information is present for this provider."
                    );
                }

                Console.WriteLine(
                    $"Provider task complete payments found: {paymentList.Count}"
                );

                return Ok(paymentList);
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    $"Error while getting provider task complete payments: {ex}"
                );

                return StatusCode(
                    500,
                    $"An error occurred while getting provider task complete payment information: {ex.Message}"
                );
            }
        }

        [HttpPost("adminaddnot")]
        [Authorize(Policy = "RequireProviderRole")]
        public async Task<IActionResult> AdminAddNotification(
    [FromBody] MessageDTO model)
        {
            try
            {
           

                var ProviderEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;

                Console.WriteLine($"Provider Email From JWT: {ProviderEmail}");

                if (string.IsNullOrWhiteSpace(ProviderEmail))
                {
                    return StatusCode(401, new
                    {
                        message = "Provider email not found in JWT."
                    });
                }


                // =========================================================
                // 2. VERIFY PROVIDER
                // =========================================================

                var Provider = await Database.UserInfos
                    .FirstOrDefaultAsync(x =>
                        x.Email == ProviderEmail &&
                        x.Role == "provider");

                if (Provider == null)
                {
                    Console.WriteLine("Provider verification failed.");

                    return StatusCode(403, new
                    {
                        message = "Provider not found."
                    });
                }

        


                // =========================================================
                // 3. VALIDATE MODEL
                // =========================================================

                if (model == null)
                {
                    return StatusCode(400, new
                    {
                        message = "Notification data is required."
                    });
                }

                if (string.IsNullOrWhiteSpace(model.Message))
                {
                    return StatusCode(400, new
                    {
                        message = "Message is required."
                    });
                }


                // =========================================================
                // 4. GET ALL ADMIN USERS WHO HAVE LOGIN ACCESS
                // =========================================================

                var AdminList = await Database.UserInfos
                    .Where(x =>
                        x.Role == "admin" &&
                        x.LoginAccess == true)
                    .ToListAsync();

        

                if (AdminList.Count == 0)
                {
                    return StatusCode(404, new
                    {
                        message = "No active admin found."
                    });
                }


                // =========================================================
                // 5. CREATE NOTIFICATIONS
                // =========================================================

                // =========================================================
                // 5. CREATE NOTIFICATIONS
                // =========================================================

                foreach (var Admin in AdminList)
                {
                    // -----------------------------------------------------
                    // NotificationInfoModel
                    // Always add a new notification
                    // -----------------------------------------------------

                    var Notification = new NotificationInfoModel
                    {
                        ReceiverNumber = Admin.UserNumber,
                        Message = model.Message.Trim(),
                        Date = DateTime.UtcNow
                    };

                    await Database.NotificationInfos.AddAsync(Notification);


                    // -----------------------------------------------------
                    // NewNotificationInfoModel
                    // If admin already exists -> update Status = true
                    // If admin does not exist -> add new row
                    // -----------------------------------------------------

                    var ExistingNewNotification =
                        await Database.NewNotificationInfos
                            .FirstOrDefaultAsync(x =>
                                x.ReceiverNumber == Admin.UserNumber);

                    if (ExistingNewNotification != null)
                    {
                        // Admin already has a notification status row
                        ExistingNewNotification.Status = true;

                        Database.NewNotificationInfos.Update(
                            ExistingNewNotification);
                    }
                    else
                    {
                        // Admin does not have a notification status row
                        var NewNotification = new NewNotificationInfoModel
                        {
                            ReceiverNumber = Admin.UserNumber,
                            Status = true
                        };

                        await Database.NewNotificationInfos.AddAsync(
                            NewNotification);
                    }
                }


                // =========================================================
                // 6. SAVE DATABASE
                // =========================================================

                await Database.SaveChangesAsync();



                return StatusCode(200, new
                {
                    message = "Notification sent successfully to all active admins."
                });
            }
            catch (Exception ex)
            {
       

                return StatusCode(500, new
                {
                    message = "Something went wrong while adding notification.",
                    error = ex.Message
                });
            }
        }
















    }
}
