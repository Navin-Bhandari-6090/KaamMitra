using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Security.Cryptography;
using System.Text;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProfileController : ControllerBase
    {

        public DatabaseController Database { get; set; }

        public ProfileController(DatabaseController Database)
        {
            this.Database = Database;
         
      
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getuserinfo")]
        public async Task<IActionResult> GetUserInfo([FromBody] UserEmailInfoModel obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    Console.WriteLine("console emssage");
                    return Ok(user_data);

                }
                return StatusCode(500, "Database error while getting user info for profile screen using username.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updateprofilephoto")]
        public async Task<IActionResult> UpdateProfilePhoto([FromBody] UserProviderPhoto obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    user_data.Photo = obj.Photo;
                    await Database.SaveChangesAsync();
                    return Ok(obj);

                }
                return StatusCode(500, "Database error while getting user info for profile screen using username.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderRole")]
        [HttpPost]
        [Route("addservice")]
        public async Task<IActionResult> AddService([FromBody] ProviderServices obj)
        {

            try
            {
                if (ModelState.IsValid)
                {
                    var Service_Data = await Database.ProviderServiceInfo.AnyAsync(x=>x.Email==obj.Email && x.ServiceName==obj.ServiceName);
                    if (Service_Data == false)
                    {
                        var user_data = await Database.ProviderServiceInfo.AddAsync(obj);
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else 
                    {
                        return StatusCode(502, "Current user service alread register in that service.");
                    }
                }
                else { 
                return StatusCode(500, "Data are not in correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderRole")]
        [HttpPost]
        [Route("addserviceresources")]
        public async Task<IActionResult> AddServiceResources([FromBody] ProviderServiceResources obj)
        {

            try
            {
                if (ModelState.IsValid)
                {

                    var ServiceData = await Database.ProviderServiceInfo.FirstOrDefaultAsync(X=>X.ProviderServiceId==obj.ProviderServiceId && X.Email==obj.Email);
                    if (ServiceData != null)
                    {
                        var Service_Resources = await Database.ProviderServiceResourcesInfo.AddAsync(obj);
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else {
                        return StatusCode(502,"Service not present with that ID or current user service id mismatch.");
                    }
                  
                }
                else
                {
                    return StatusCode(500, "Data are not in correct format.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        private string HashPasswordUpdate(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                // Compute hash for the password
                var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                // Convert the byte array to a hexadecimal string
                if (hashedBytes != null)
                {
                    return BitConverter.ToString(hashedBytes).Replace("-", "").ToLower();
                }
                else
                {
                    return "";
                }

            }

        }

        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPut]
        [Route("updatepassword")]
        public async Task<IActionResult> UpdatePassword([FromBody] LoginModel obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {

                    user_data.Password =HashPasswordUpdate(obj.Password);
                    await Database.SaveChangesAsync();
                    return Ok();

                }
                return StatusCode(500, "Database error while getting user info for profile screen using username.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("updateservicedocument")]
        public async Task<IActionResult> UpdateServiceFile([FromBody] UpdateServiceFile obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    var Service_Data = await Database.ProviderServiceInfo.FirstOrDefaultAsync(x=>x.Email==obj.Email && x.ProviderServiceId==obj.ProviderServiceId);
                    if (Service_Data != null)
                    {
                        Service_Data.ServiceDocument = obj.ServiceDocument;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else {
                        return StatusCode(502, "No service available.");
                    }
                 
                }
                return StatusCode(500, "Database error while getting user info for profile screen using username.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireProviderRole")]
        [HttpPut]
        [Route("updateserviceresources")]
        public async Task<IActionResult> UpdateServiceResources([FromBody] UpdateServiceResources obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    var Service_Data = await Database.ProviderServiceResourcesInfo.FirstOrDefaultAsync(x => x.Email == obj.Email && x.ProviderServiceResourcesId == obj.ProviderServiceResourcesId);
                    if (Service_Data != null)
                    {
                        Service_Data.ServicePhoto = obj.ServicePhoto;
                        Service_Data.ServiceVideo = obj.ServiceVideo;
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else
                    {
                        return StatusCode(502, "No service register of the current user.");
                    }

                }
                return StatusCode(500, "Database error while getting user info for profile screen using username.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


        [Authorize(Policy= "RequireProviderRole")]
        [HttpPost]
        [Route("getserviceinfo")]
        public async Task<IActionResult> GetServiceInfo([FromBody] UserEmailInfoModel obj)
        {

            try
            {
                var user_data = await Database.UserInfos.FirstOrDefaultAsync(x => x.Email == obj.Email);
                if (user_data != null)
                {
                    var Service_Data = await Database.ServiceInfos.OrderBy(x => x.ServiceName).ToListAsync();
                    return Ok(Service_Data);

                }
                return StatusCode(500, "No user found.");
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getservicephotoinfo")]
        public async Task<IActionResult> GetServicePhotoInfo(
     [FromBody] ProviderServiceEmailServiceNameModel obj)
        {
            try
            {
                // 1. Check whether user exists
                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (userData == null)
                {
                    return NotFound("No user found.");
                }

                // 2. Get service + resource information
                var servicePhotos = await Database.ProviderServiceInfo
                    .Where(x => x.Email == obj.Email && x.ServiceName == obj.ServiceName)
                    .SelectMany(
                        service => service.ProviderServicesResources,
                        (service, resource) => new SendServicePhoto
                        {
                            ServiceName = service.ServiceName,
                            ProviderServiceResourcesId =
                                resource.ProviderServiceResourcesId,
                            ServicePhoto = resource.ServicePhoto,
                            ProviderServiceId = resource.ProviderServiceId
                        })
                    .ToListAsync();

                // 3. Check whether resources exist
                if (servicePhotos.Count == 0)
                {
                    return NotFound(
                        "No service resources found for the current user.");
                }

                return Ok(servicePhotos);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getproviderregisterserviceinfo")]
        public async Task<IActionResult> GetProviderServiceInfo(
            [FromBody] UserEmailInfoModel obj)
        {
            try
            {
                var user_data = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (user_data == null)
                {
                    return NotFound("No user found.");
                }

                var Service_Data = await Database.ProviderServiceInfo
                    .Where(x => x.Email == obj.Email)
                    .Select(x => new
                    {
                        ServiceName = x.ServiceName
                    })
                    .OrderBy(x => x.ServiceName)
                    .ToListAsync();

                if (Service_Data.Count > 0)
                {
                    return Ok(Service_Data);
                }
                else
                {
                    return NotFound("No service registered for current user.");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }


        [Authorize(Policy = "RequireProviderUserRole")]
        [HttpPost]
        [Route("getservicefileinfo")]
        public async Task<IActionResult> GetServiceFileInfo(
            [FromBody] ProviderServiceEmailServiceNameModel obj)
        {
            try
            {
                // 1. Check whether user exists
                var userData = await Database.UserInfos
                    .FirstOrDefaultAsync(x => x.Email == obj.Email);

                if (userData == null)
                {
                    return NotFound("No user found.");
                }

                // 2. Get service information
                var serviceFiles = await Database.ProviderServiceInfo
                    .Where(x =>
                        x.Email == obj.Email &&
                        x.ServiceName == obj.ServiceName)
                    .Select(x => new
                    {
                        ProviderServiceId = x.ProviderServiceId,
                        ServiceName = x.ServiceName,
                        ServiceDocument = x.ServiceDocument
                    })
                    .ToListAsync();

                // 3. Check whether service exists
                if (serviceFiles.Count == 0)
                {
                    return NotFound(
                        "No service found for the current user.");
                }

                return Ok(serviceFiles);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }





    }
}
