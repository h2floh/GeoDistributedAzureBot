using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    [ApiController]
    public class DirectlineController : ControllerBase
    {
        private readonly Directline directline;
        public DirectlineController(Directline directline)
        {
            this.directline = directline;
        }

        [Route("directline/token")]
        [HttpGet]
        public async Task<DirectlineToken> GetAsync()
        {
            DirectlineToken directlineToken = new DirectlineToken
            {
                token = await directline.GetDirectlineToken()
            };

            return directlineToken;
        }
    }

    public class DirectlineToken
    {
        public string token { get; set; }
    }
}