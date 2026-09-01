using application.Data;
using application.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace application.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        public DatabaseController Database { get; set; }



        public AdminController(DatabaseController Database)
        {
            this.Database = Database;
     
        }

        [HttpGet]
        [Route("getservicenormal")]
        public async Task<IActionResult> GetServiceInfo1()
        {

            try
            {
                var Service_Data = await Database.ServiceInfos.ToListAsync();
                return Ok(Service_Data);
            }
            catch (Exception ex)
            {
                return StatusCode(501, ex.Message);
            }
        }

        [Authorize(Policy = "RequireAdminRole")]
        [HttpPost]
        [Route("registerservice")]
        public async Task<IActionResult> AddService([FromBody] ServiceInfoModel obj)
        {

            try
            {
                if (ModelState.IsValid)
                {
                    var Service_Data = await Database.ServiceInfos.AnyAsync(x => x.ServiceName==obj.ServiceName);
                    if (Service_Data == false)
                    {
                        var user_data = await Database.ServiceInfos.AddAsync(obj);
                        await Database.SaveChangesAsync();
                        return Ok();
                    }
                    else
                    {
                        return StatusCode(502, "Service alread register in that service.");
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






    }
}
