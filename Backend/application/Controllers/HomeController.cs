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
    public class HomeController : ControllerBase
    {

        public DatabaseController Database { get; set; }
 


        public HomeController(DatabaseController Database, IWebHostEnvironment Environment)
        {
            this.Database = Database;
        

        }



        [HttpGet("getfooterinfo")]
        [Authorize(Policy = "RequireforAllRole")]
        public async Task<IActionResult> GetFooterInfo()
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

                var footerInfo = await Database.FooterInfos
                    .AsNoTracking()
                    .FirstOrDefaultAsync();

                if (footerInfo == null)
                {
                    return StatusCode(404, new
                    {
                        message = "Footer information not found."
                    });
                }

                return StatusCode(200, footerInfo);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Something went wrong while getting footer information.",
                    error = ex.Message
                });
            }
        }

        [HttpPost()]
        [Authorize(Policy = "RequireProviderUserRole")]
        [Route("addchatmessage")]
        public async Task<IActionResult> AddChatMessage(
    [FromBody] ChatInfoModel model)
        {
            try
            {
                // Validate request model
                if (!ModelState.IsValid)
                {
                    return StatusCode(400, new
                    {
                        Message = "Invalid chat message data."
                    });
                }

                var userNumberClaim =
User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userNumberClaim, out int currentUserNumber))
                {
                    return StatusCode(506);
                }


                var user = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.UserNumber == currentUserNumber);

                if (user == null)
                {

                    return StatusCode(507, "User not found");
                }


                if (user.LoginAccess == false)
                {
                    return StatusCode(508, "You have been blocked by System.Contact to KaamMitra community.");
                }

                var ReceiverNumberData = await Database.UserInfos
           .FirstOrDefaultAsync(x => x.UserNumber == model.ReceiverNumber);

                if (ReceiverNumberData == null)
                {
                    return StatusCode(508, "Another user not found");
                }


                if (ReceiverNumberData.LoginAccess == false)
                {
                    return StatusCode(509, "Anotehr user have been blocked by System.Contact to KaamMitra community.");
                }

                // Create message using authenticated sender
                var ChatMessage = new ChatInfoModel
                {
                    Message = model.Message.Trim(),
                    SenderNumber = currentUserNumber,
                    ReceiverNumber = model.ReceiverNumber,
                    StoreAt = DateTime.UtcNow
                };

                // Save to database
               await Database.ChatInfos.AddAsync(ChatMessage);

                await Database.SaveChangesAsync();

                return Ok(200);
            }
            catch (Exception ex)
            {
             

                return StatusCode(500, new
                {
                    Message = "Something went wrong while saving the chat message."
                });
            }
        }

      
[HttpPost]
[Authorize(Policy = "RequireProviderUserRole")]
        [Route("getchatmessage")]
        public async Task<IActionResult> GetChatMessages([FromBody] UserNumberDTO model)
        {
            try
            {
     

                // Get current user's number from JWT
                var CurrentUserNumberClaim = User.FindFirst(
                    System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrWhiteSpace(CurrentUserNumberClaim) ||
                    !int.TryParse(CurrentUserNumberClaim, out int CurrentUserNumber))
                {
                    return StatusCode(506);
                }

                // Validate other user number
                if (model.UserNumber <= 0 ||
                    model.UserNumber == CurrentUserNumber)
                {
                    return StatusCode(507);
                }

           


                var CurrentUserNumberData = await Database.UserInfos
                .FirstOrDefaultAsync(x => x.UserNumber == CurrentUserNumber);

                if (CurrentUserNumberData == null)
                {
                    return StatusCode(510, "Current user  not found");
                }


                if (CurrentUserNumberData.LoginAccess == false)
                {
                    return StatusCode(511, "Current user have been blocked by System.Contact to KaamMitra community.");
                }

                var OtherUserNumber = model.UserNumber;

                // Retrieve messages in both directions
                var ChatMessages = await Database.ChatInfos
                    .Where(x =>
                        (x.SenderNumber == CurrentUserNumber &&
                         x.ReceiverNumber == OtherUserNumber)
                        ||
                        (x.SenderNumber == OtherUserNumber &&
                         x.ReceiverNumber == CurrentUserNumber))
                    .OrderBy(x => x.StoreAt)
                    .ThenBy(x => x.ChatId)
                    .ToListAsync();

          

                return StatusCode(200, ChatMessages);
            }
            catch (Exception ex)
            {
           
                return StatusCode(500);
            }
        }












    }
}
