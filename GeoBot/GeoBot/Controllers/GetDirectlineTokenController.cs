using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    
    [ApiController]
    public class GetDirectlineTokenController : ControllerBase
    {
        private readonly Healthcheck healthcheck;
        public GetDirectlineTokenController(Healthcheck healthcheck)
        {
            this.healthcheck = healthcheck;
        }

        [Route("directline/token")]
        [HttpGet]
        public async Task<Token> GetAsync()
        {
            Token token = new Token
            {
                token = await healthcheck.GetDirectlineToken()
            };

            return token;
        }
    }

    public class Token
    {
        public string token { get; set; }
    }

}